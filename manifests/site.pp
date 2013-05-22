
## This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

####### shared variables ##################

#Exec {
#  logoutput => true,
#}

# database config
$mysql_root_password  = hiera('mysql_root_password', 'mysql_root_password')
$keystone_db_password = hiera('keystone_db_password', 'keystone_db_password')
$glance_db_password   = hiera('glance_db_password', 'glance_db_password')
$nova_db_password     = hiera('nova_db_password', 'nova_db_password')
$cinder_db_password   = hiera('cinder_db_password', 'cinder_db_password')
$quantum_db_password  = hiera('quantum_db_password', 'quantum_db_password')

$allowed_hosts        = hiera('allowed_hosts', ['%'])

# keystone settings)
$admin_token           = hiera('admin_token', 'service_token')
$admin_email           = hiera('admin_email', 'keystone@localhost')
$admin_password        = hiera('admin_password', 'ChangeMe')
$glance_user_password  = hiera('glance_user_password', 'glance_user_password')
$nova_user_password    = hiera('nova_user_password', 'nova_user_password')
$cinder_user_password  = hiera('cinder_user_password', 'cinder_user_password')
$quantum_user_password = hiera('quantum_user_password', 'quantum_user_password')

$verbose           = hiera('verbose', 'True')

$public_interface  = hiera('public_interface', 'eth0')
$private_interface = hiera('private_interface', 'eth2')

$rabbit_password   = hiera('rabbit_password', 'rabbit_password')
$rabbit_user       = hiera('rabbit_user', 'nova')

$secret_key        = hiera('secret_key', 'secret_key')

$libvirt_type      = hiera('libvirt_type', 'qemu')
#$network_type      = hiera('', 'quantum')
$network_type      = hiera('network_type', 'nova')
if $network_type == 'nova' {
  $use_quantum  = false
  $multi_host   = true
  $nova_network = true
} else {
  $nova_network = false
  $use_quantum = true
}

$fixed_network_range     = hiera('fixed_network_range', '10.0.0.0/24')
$floating_network_range  = hiera('floating_network_range', '172.16.0.128/25')

$auto_assign_floating_ip = hiera('auto_assign_floating_ip', false)

#### end shared variables #################

#### controller/compute mode settings ####
$openstack_controller = hiera('openstack_controller', '172.16.0.3')
#### controller/compute mode settings ####
$openstack_version    = hiera('openstack_version', 'folsom')

# node declaration for all in one
import 'scenarios/all_in_one.pp'
# node declarations for a single server per role
import 'scenarios/multi_role.pp'

# import external swift definitions
import '/etc/puppet/modules-0/swift/examples/site.pp'

node /openstack-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file':
    quantum     => $use_quantum,
    sleep_time  => 120,
    floating_ip => $nova_network,
  }

  if $::osfamily == 'Redhat' {
    # redhat specific dashboard stuff
    file_line { 'nova_sudoers':
      line   => 'nova ALL = (root) NOPASSWD: /usr/bin/nova-rootwrap /etc/nova/rootwrap.conf *',
      path   => '/etc/sudoers',
      before => Package['nova-common'],
    }

    nova_config { 'DEFAULT/rpc_backend': value => 'nova.openstack.common.rpc.impl_kombu';}
    cinder_config { 'DEFAULT/rpc_backend': value => 'cinder.openstack.common.rpc.impl_kombu';}
    #selboolean{'httpd_can_network_connect':
    #  value => on,
    #  persistent => true,
    #}

    firewall { '001 horizon incomming':
      proto    => 'tcp',
      dport    => ['80'],
      action   => 'accept',
    }
    firewall { '001 glance incomming':
      proto    => 'tcp',
      dport    => ['9292'],
      action   => 'accept',
    }
    firewall { '001 keystone incomming':
      proto    => 'tcp',
      dport    => ['5000', '35357'],
      action   => 'accept',
    }

    firewall { '001 mysql incomming':
      proto    => 'tcp',
      dport    => ['3306'],
      action   => 'accept',
    }
    firewall { '001 novaapi incomming':
      proto    => 'tcp',
      dport    => ['8773', '8774', '8776'],
      action   => 'accept',
    }
    firewall { '001 qpid incomming':
      proto    => 'tcp',
      dport    => ['5672'],
      action   => 'accept',
    }
    firewall { '001 novncproxy incomming':
      proto    => 'tcp',
      dport    => ['6080'],
      action   => 'accept',
    }
  }

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
  # horizon
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
    horizon_app_links      => undef,
    # General
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
    if $::osfamily == 'Debian' {
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
    } elsif $::osfamily == 'RedHat' {

      cinder_config { 'DEFAULT/rpc_backend': value => 'cinder.openstack.common.rpc.impl_kombu';}

      file_line { 'nova_sudoers':
        line   => 'nova ALL = (root) NOPASSWD: /usr/bin/nova-rootwrap /etc/nova/rootwrap.conf *',
        path   => '/etc/sudoers',
        before => Service['nova-network'],
      }
      file_line { 'cinder_sudoers':
        line    => 'cinder ALL = (root) NOPASSWD: /usr/bin/cinder-rootwrap /etc/cinder/rootwrap.conf *',
        path    => '/etc/sudoers',
        before  => Service['cinder-volume'],
      }

      nova_config { 'DEFAULT/rpc_backend': value => 'nova.openstack.common.rpc.impl_kombu';}

      nova_config{
        "DEFAULT/network_host": value => $openstack_controller;
        "DEFAULT/libvirt_inject_partition": value => "-1";
      }
      if $libvirt_type == "qemu" {
        file { "/usr/bin/qemu-system-x86_64":
          ensure => link,
          target => "/usr/libexec/qemu-kvm",
          notify => Service["nova-compute"],
        }
      }
      firewall { '001 vnc listen incomming':
        proto    => 'tcp',
        dport    => ['6080'],
        action   => 'accept',
      }
      firewall { '001 volume incomming':
        proto    => 'tcp',
        dport    => ['3260'],
        action   => 'accept',
      }
    }
  }

  class { 'cinder::setup_test_volume': } -> Service<||>

  class { 'openstack::compute':
    public_interface       => $public_interface,
    private_interface      => $private_interface,
    internal_address       => $::ipaddress_eth1,
    libvirt_type           => $libvirt_type,
    sql_connection         => "mysql://nova:${nova_db_password}@${openstack_controller}/nova",
    cinder_sql_connection  => "mysql://cinder:${cinder_db_password}@${openstack_controller}/cinder",
    multi_host             => $multi_host,
    fixed_range            => $fixed_network_range,
    nova_user_password     => $nova_user_password,
    quantum                => $use_quantum,
    quantum_host           => $openstack_controller,
    quantum_user_password  => $quantum_user_password,
    rabbit_password        => $rabbit_password,
    glance_api_servers     => ["${openstack_controller}:9292"],
    rabbit_host            => $openstack_controller,
    keystone_host          => $openstack_controller,
    vncproxy_host          => $openstack_controller,
    vnc_enabled            => true,
    verbose                => $verbose,
  }

}


node /tempest/ {

  if $::openstack_version == 'folsom' {
    # this assumes that tempest is being run on the same node
    # as the openstack controller

    if $osfamily == 'redhat' {
      $nova_api_service_name = 'openstack-nova-api'
    } else {
      $nova_api_service_name = 'nova-api'
    }

    service { 'nova-api':
      name => $nova_api_service_name
    }
    Nova_config<||> ~> Service['nova-api']
    Nova_paste_api_ini<||> ~> Service['nova-api']

    nova_config { 'DEFAULT/api_rate_limit': value => 'false' }

    # remove rate limiting
    # this may be folsom specific
    nova_paste_api_ini {
      'composite:openstack_compute_api_v2/noauth':   value => 'faultwrap sizelimit noauth osapi_compute_app_v2';
      'composite:openstack_compute_api_v2/keystone': value => 'faultwrap sizelimit authtoken keystonecontext osapi_compute_app_v2';
      'composite:openstack_volume_api_v1/noauth':    value => 'faultwrap sizelimit noauth osapi_volume_app_v1';
      'composite:openstack_volume_api_v1/keystone':  value => 'faultwrap sizelimit authtoken keystonecontext osapi_volume_app_v1';
    }
  }

  if ($::openstack_version == 'grizzly') {
    $revision = 'master'
  } else {
    $revision = $::openstack_version
  }

  class { 'tempest':
    identity_host        => $::openstack_controller,
    identity_port        => '35357',
    identity_api_version => 'v2.0',
    # non admin user
    username             => 'user1',
    password             => 'user1_password',
    tenant_name          => 'tenant1',
    # another non-admin user
    alt_username         => 'user2',
    alt_password         => 'user2_password',
    alt_tenant_name      => 'tenant2',
    # image information
    image_id             => 'XXXXXXX',#<%= image_id %>,
    image_id_alt         => 'XXXXXXX',#<%= image_id_alt %>,
    flavor_ref           => 1,
    flavor_ref_alt       => 2,
    # the version of the openstack images api to use
    image_api_version    => '1',
    image_host           => $::openstack_controller,
    image_port           => '9292',

    # this should be the username of a user with administrative privileges
    admin_username       => 'admin',
    admin_password       => $::admin_password,
    admin_tenant_name    => 'admin',
    nova_db_uri          => 'mysql://nova:nova_db_password@127.0.0.1/nova',
    version_to_test      => $revision,
  }

  class { 'openstack::auth_file':
    admin_password       => $::admin_password,
    keystone_admin_token => $::admin_token,
    controller_node      => $::openstack_controller,
  }

}

node /devstack/ {

  class { 'devstack': }

}

node default {
  notify { $clientcert: }
}

node puppetmaster {

  $hostname = 'puppetmaster'

  ### Add the puppetlabs repo
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
    tag       => ['puppet'],
  }

  Exec["apt_update"] -> Package <| |>

  package { ['hiera', 'hiera-puppet']:
    ensure   => present,
    provider => 'gem',
    require  => Package['puppetmaster'],
  }

  class { 'puppet::master':
    autosign   => true,
    modulepath => '/etc/puppet/modules-0',
  }

  class { 'puppetdb':
    require => Class['puppet::master'],
  }

  # Configure the puppet master to use puppetdb.
  class { 'puppetdb::master::config':
    restart_puppet           => false,
    puppetdb_startup_timeout => 240,
    notify                   => Class['apache'],
  }

}
