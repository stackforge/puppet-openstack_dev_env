
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

$allowed_hosts        = ['keystone', 'glance', 'novacontroller', 'compute1', '%']

# keystone settings
$admin_token           = 'service_token'
$admin_email           = 'keystone@localhost'
$admin_password        = 'ChangeMe'
$glance_user_password  = 'glance_user_password'
$nova_user_password    = 'nova_user_password'

$verbose = 'True'

$public_interface = 'eth1'
$private_interface = 'eth2'

$rabbit_password = 'rabbit_password'
$rabbit_user     = 'nova'

$secret_key      = 'secret_key'

$libvirt_type = 'qemu'

#### end shared variables #################

#### controller/compute mode settings ####
$mysql_host    = '172.16.5.8'
$keystone_host = '172.16.5.7'
$glance_host   = '172.16.5.6'
$nova_host     = '172.16.5.5'
#### controller/compute mode settings ####
$openstack_controller = '172.16.5.3'
#### controller/compute mode settings ####

node /mysql/ {

  class { 'openstack::db::mysql':
    mysql_root_password  => $mysql_root_password,
    keystone_db_password => $keystone_db_password,
    glance_db_password   => $glance_db_password,
    nova_db_password     => $nova_db_password,
    allowed_hosts        => $allowed_hosts,
  }

}

node /keystone/ {

  class { 'openstack::keystone':
    db_host               => $mysql_host,
    db_password           => $keystone_db_password,
    admin_token           => $admin_token,
    admin_email           => $admin_email,
    admin_password        => $admin_password,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    public_address        => $keystone_host,
    glance_public_address => $glance_host,
    nova_public_address   => $nova_host,
    verbose               => $verbose,
  }
}

node /glance/ {

  class { 'openstack::glance':
    db_host               => $mysql_host,
    glance_user_password  => $glance_user_password,
    glance_db_password    => $glance_db_password,
    keystone_host         => $keystone_host,
    auth_uri              => "http://${keystone_host}:5000/",
    verbose               => $verbose,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => $keystone_host,
  }
}

node /openstack-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

#  class { 'nova::volume': enabled => true }
#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    #floating_range          => $floating_network_range,
    internal_address       => $openstack_controller,
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
  # Required Horizon

    secret_key             => $secret_key,
    # need to sort out networking...
    network_manager        => 'nova.network.manager.FlatDHCPManager',
    fixed_range            => '10.0.0.0/24',
    floating_range         => '172.16.5.64/25',
    create_networks        => true,
    multi_host             => true,
    # not supported for essex
    #db_host                => '127.0.0.1',
    #db_type                => 'mysql',
    #mysql_account_security => true,
    #
    # TODO - this should not allow all
    # allowed in folsom
    #allowed_hosts          => '%',
    # Keystone
    # Glance
    # folsome release only param
    #glance_api_servers     => '127.0.0.1:9292',
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    # Horizon
    cache_server_ip        => '127.0.0.1',
    cache_server_port      => '11211',
    swift                  => false,
    quantum                => false,
    horizon_app_links      => undef,
    # Genera
    verbose                => $verbose,
    # not supported in essex branch
    # purge_nova_config      => false,
    export_resources       => false,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => '127.0.0.1',
  }

}

node /nova-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

#  class { 'nova::volume': enabled => true }
#  class { 'nova::volume::iscsi': }

  class { 'openstack::nova::controller':
    public_address     => '172.16.5.5',
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    db_host            => '172.16.5.8',
    rabbit_password    => $rabbit_password,
    nova_user_password => $nova_user_password,
    nova_db_password   => $nova_db_password,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    verbose            => $verbose,
    multi_host         => true,
    glance_api_servers => '172.16.5.6:9292',
    keystone_host      => '172.16.5.7',
    #floating_range          => $floating_network_range,
    #fixed_range             => $fixed_network_range,
  }

  class { 'openstack::horizon':
    secret_key            => $secret_key,
    cache_server_ip       => '127.0.0.1',
    cache_server_port     => '11211',
    swift                 => false,
    quantum               => false,
    horizon_app_links     => undef,
    keystone_host         => '172.16.5.7',
    keystone_default_role => 'Member',
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => '172.16.5.7',
  }

}

node /compute/ {

  # TODO not sure why this is required
  #Package['libvirt'] ->
  #file_line { 'quemu_hack':
  #  line => 'cgroup_device_acl = [
  # "/dev/null", "/dev/full", "/dev/zero",
  # "/dev/random", "/dev/urandom",
  # "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
  # "/dev/rtc", "/dev/hpet", "/dev/net/tun",]',
  #  path   => '/etc/libvirt/qemu.conf',
  #  ensure => present,
  #} ~> Service['libvirt']

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

  # External lookups.
  # $rabbit_connection_hash = collect_rabbit_connection('ipaddress_eth1', 'architecture=amd64')
  # $nova_db_addr = collect_nova_db_connection('ipaddress_eth1', 'architecture=amd64')
  # $vnc_proxy_addr = unique(query_nodes('Class[nova::vncproxy]', 'ipaddress_eth1'))
  # $glance_api_addr = unique(query_nodes('Class[glance::api]', 'ipaddress_eth1'))

  class { 'openstack::compute':
    private_interface  => $private_interface,
    public_interface   => $public_interface,
    internal_address   => $::ipaddress_eth1,
    libvirt_type       => $libvirt_type,
    sql_connection     => "mysql://nova:${nova_db_password}@${openstack_controller}/nova",
    multi_host         => true,
    nova_user_password => $nova_user_password,
    rabbit_host        => $openstack_controller,
    rabbit_password    => $rabbit_password,
    glance_api_servers => ["${openstack_controller}:9292"],
    vncproxy_host      => $openstack_controller,
    vnc_enabled        => true,
    verbose            => $verbose,
  }

}

node /devstack/ {

  class { 'devstack': }

}

node default {
  notify { $clientcert: }
}
