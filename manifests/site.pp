
## This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#


####### shared variables ##################

Exec {
  logoutput => true,
}

# database config
$mysql_root_password  = 'mysql_root_password'
$keystone_db_password = 'keystone_db_password'
$glance_db_password   = 'glance_db_password'
$nova_db_password     = 'nova_db_password'
$cinder_db_password   = 'cinder_db_password'
$quantum_db_password  = 'quantum_db_password'

$allowed_hosts        = ['%']

# keystone settings
$admin_token           = 'service_token'
$admin_email           = 'keystone@localhost'
$admin_password        = 'ChangeMe'
$glance_user_password  = 'glance_user_password'
$nova_user_password    = 'nova_user_password'
$cinder_user_password  = 'cinder_user_password'
$quantum_user_password = 'quantum_user_password'

$verbose = 'True'

$public_interface  = 'eth1'
$private_interface = 'eth2'

$rabbit_password   = 'rabbit_password'
$rabbit_user       = 'nova'

$secret_key        = 'secret_key'

$libvirt_type      = 'qemu'
#$libvirt_type = 'kvm'
$network_type      = 'quantum'
#$network_type      = 'nova'
if $network_type == 'nova' {
  $use_quantum = false
  $multi_host  = true
} else {
  $use_quamtum = true
}

$fixed_network_range     = '10.0.0.0/24'
$floating_network_range  = '172.16.0.128/25'

$auto_assign_floating_ip = false

#### end shared variables #################

#### controller/compute mode settings ####
$openstack_controller = '172.16.0.3'
#### controller/compute mode settings ####

# node declaration for all in one
import 'scenarios/all_in_one.pp'
# node declarations for a single server per role
import 'scenarios/multi_role.pp'

node /openstack-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file':
    quantum => $use_quantum,
  }

  include apache

  class { 'openstack::controller':
    #floating_range          => $floating_network_range,
  # Required Network
    public_address         => $openstack_controller,
    public_interface       => $public_interface,
    private_interface      => $private_interface,
  # Required Database
    mysql_root_password    => $mysql_root_password,
  # Required Keystone
    admin_email            => $admin_email,
    admin_password         => $admin_password,
    keystone_db_password   => $keystone_db_password,
    keystone_admin_token   => $admin_token,
  # Required Glance
    glance_db_password     => $glance_db_password,
    glance_user_password   => $glance_user_password,
  # Required Nov a
    nova_db_password       => $nova_db_password,
    nova_user_password     => $nova_user_password,
  # cinder
    cinder_db_password     => $cinder_db_password,
    cinder_user_password   => $cinder_user_password,
    cinder                 => true,
  # quantum
    quantum                => $use_quantum,
    quantum_db_password    => $quantum_db_password,
    quantum_user_password  => $quantum_user_password,
  # Required Horizon

    secret_key             => $secret_key,
    # need to sort out networking...
    network_manager        => 'nova.network.manager.FlatDHCPManager',
    fixed_range            => $fixed_network_range,
    floating_range         => $floating_network_range,
    create_networks        => true,
    multi_host             => $multi_host,
    db_host                => '127.0.0.1',
    db_type                => 'mysql',
    mysql_account_security => true,
    # TODO - this should not allow all
    allowed_hosts          => '%',
    # Keystone
    # Glance
    glance_api_servers     => '127.0.0.1:9292',
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    # Horizon
    cache_server_ip        => '127.0.0.1',
    cache_server_port      => '11211',
    swift                  => false,
    horizon_app_links      => undef,
    # Genera
    verbose                => $verbose,
    purge_nova_config      => false,
  }

  package { 'python-cliff':
    ensure => present,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => '127.0.0.1',
  }

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }
}

node /compute/ {

  # TODO not sure why this is required
  # this has a bug, and is constantly added to the file
  if $libvirt_type == 'qemu' {
    Package['libvirt'] ->
    file_line { 'quemu_hack':
      line => 'cgroup_device_acl = [
     "/dev/null", "/dev/full", "/dev/zero",
     "/dev/random", "/dev/urandom",
     "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
     "/dev/rtc", "/dev/hpet", "/dev/net/tun",]',
      path   => '/etc/libvirt/qemu.conf',
      ensure => present,
    } ~> Service['libvirt']
  }

  # External lookups.
  # $rabbit_connection_hash = collect_rabbit_connection('ipaddress_eth1', 'architecture=amd64')
  # $nova_db_addr = collect_nova_db_connection('ipaddress_eth1', 'architecture=amd64')
  # $vnc_proxy_addr = unique(query_nodes('Class[nova::vncproxy]', 'ipaddress_eth1'))
  # $glance_api_addr = unique(query_nodes('Class[glance::api]', 'ipaddress_eth1'))

  #
  # This is just for testing. It creates a loopback interface
  # that can be mounted by cinder. In real deployments, you should
  # partition your physical disks to have volume groups.
  #
  class { 'cinder::setup_test_volume': } -> Service<||>

  class { 'openstack::compute':
    public_interface       => $public_interface,
    private_interface      => $private_interface,
    internal_address       => $::ipaddress_eth1,
    libvirt_type           => $libvirt_type,
    sql_connection         => "mysql://nova:${nova_db_password}@${openstack_controller}/nova",
    cinder_sql_connection  => "mysql://cinder:${cinder_db_password}@${openstack_controller}/cinder",
    quantum_sql_connection => "mysql://quantum:${quantum_db_password}@${openstack_controller}/quantum?charset=utf8",
    multi_host             => $multi_host,
    nova_user_password     => $nova_user_password,
    quantum_user_password  => $quantum_user_password,
    rabbit_password        => $rabbit_password,
    glance_api_servers     => ["${openstack_controller}:9292"],
    rabbit_host            => $openstack_controller,
    quantum_host           => $openstack_controller,
    keystone_host          => $openstack_controller,
    vncproxy_host          => $openstack_controller,
    vnc_enabled            => true,
    verbose                => $verbose,
  }

}

node /devstack/ {

  class { 'devstack': }

}

node default {
  notify { $clientcert: }
}
