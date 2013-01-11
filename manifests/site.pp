
## This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#


####### shared variables ##################

#Exec {
#  logoutput => true,
#}

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

$public_interface  = 'eth0'
$private_interface = 'eth2'

$rabbit_password   = 'rabbit_password'
$rabbit_user       = 'nova'

$secret_key        = 'secret_key'

$libvirt_type      = 'qemu'
#$libvirt_type = 'kvm'
#$network_type      = 'quantum'
$network_type      = 'nova'
if $network_type == 'nova' {
  $use_quantum = false
  $multi_host  = true
} else {
  $use_quantum = true
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
    quantum    => $use_quantum,
    sleep_time => 30,
  }

  if $::osfamily == 'Debian' {
    include 'apache'
  } else {
    # redhat specific dashboard stuff
    file_line { 'nova_sudoers':
      line   => 'nova ALL = (root) NOPASSWD: /usr/bin/nova-rootwrap /etc/nova/rootwrap.conf *',
      path   => '/etc/sudoers',
      before => Package['nova-common'],
    }

    class {'apache':}
    class {'apache::mod::wsgi':}
    file { '/etc/httpd/conf.d/openstack-dashboard.conf':}

    nova_config { 'rpc_backend': value => 'nova.openstack.common.rpc.impl_kombu';}
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
    swift                  => false,
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

      package { 'avahi': ensure => present } ~>
      service { 'messagebus':
        ensure => running,
        enable => true,
      } ~>
      service { 'avahi-daemon':
        ensure => running,
        enable => true,
      } ~>
      Service['libvirtd']
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

      nova_config { 'rpc_backend': value => 'nova.openstack.common.rpc.impl_kombu';}

      nova_config{
        "network_host": value => $openstack_controller;
        "libvirt_inject_partition": value => "-1";
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
    quantum_sql_connection => "mysql://quantum:${quantum_db_password}@${openstack_controller}/quantum?charset=utf8",
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
