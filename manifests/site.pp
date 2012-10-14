
## This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#


####### shared variables ##################

Exec {
  logoutput => true,
}


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack-all/ {

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

  class { 'openstack::all':
#    public_address          => $ipaddress_eth1,
#    public_interface        => $public_interface,
#    private_interface       => $private_interface,
#    admin_email             => $admin_email,
#    admin_password          => $admin_password,
#    keystone_db_password    => $keystone_db_password,
#    keystone_admin_token    => $keystone_admin_token,
#    nova_db_password        => $nova_db_password,
#    nova_user_password      => $nova_user_password,
#    glance_db_password      => $glance_db_password,
#    glance_user_password    => $glance_user_password,
#    rabbit_password         => $rabbit_password,
#    rabbit_user             => $rabbit_user,
#    libvirt_type            => 'qemu',
#    floating_range          => $floating_network_range,
#    fixed_range             => $fixed_network_range,
#    verbose                 => $verbose,
#    auto_assign_floating_ip => $auto_assign_floating_ip,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

}

node /mysql/ {

  class { 'openstack::db::mysql':
    mysql_root_password  => 'root_password',
    keystone_db_password => 'keystone_password',
    glance_db_password   => 'glance_password',
    nova_db_password     => 'nova_password',
    cinder_db_password   => 'cinder_password',
    allowed_hosts        => ['keystone', 'glance', 'novacontroller', 'compute1', '%'],
  }

}

node /keystone/ {

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  class { 'openstack::keystone':
    db_host               => '172.16.0.8',
    db_password           => 'keystone_password',
    admin_token           => 'service_token',
    admin_email           => 'keystone@localhost',
    admin_password        => 'ChangeMe',
    glance_user_password  => 'glance_password',
    nova_user_password    => 'nova_password',
    cinder_user_password  => 'cinder_password',
    public_address        => '172.16.0.7',
    admin_tenant          => 'admin',
    glance_public_address => '172.16.0.6',
    nova_public_address   => '172.16.0.5',
    verbose               => 'true',
  }
}

node /glance/ {

  class { 'openstack::glance':
    db_host               => '172.16.0.8',
    glance_user_password  => 'glance_password',
    glance_db_password    => 'glance_password',
    keystone_host         => '172.16.0.7',
    auth_uri              => "http://172.16.0.7:5000/",
    verbose               => true,
  }

  class { 'openstack::auth_file':
    admin_password       => 'ChangeMe',
    keystone_admin_token => 'service_token',
    controller_node      => '172.16.0.7',
    admin_tenant         => 'admin',
  }
}

node /openstack-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

#  class { 'nova::volume': enabled => true }
#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    #floating_range          => $floating_network_range,
  # Required Network
    public_address         => '172.16.0.3',
    public_interface       => 'eth1',
    private_interface      => 'eth2',
  # Required Database
    mysql_root_password    => 'root_password',
  # Required Keystone
    admin_email            => 'some_user@some_fake_email_address.foo',
    admin_password         => 'ChangeMe',
    keystone_db_password   => 'keystone_db_pass',
    keystone_admin_token   => 'keystone_admin_token',
  # Required Glance
    glance_db_password     => 'glance_db_pass',
    glance_user_password   => 'glance_user_pass',
  # Required Nov a
    nova_db_password       => 'nova_db_pass',
    nova_user_password     => 'nova_user_pass',
  # cinder
    cinder_db_password     => 'cinder_db_pass',
    cinder_user_password   => 'cinder_user_pass',
  # quantum
    quantum_db_password    => 'quantum_db_pass',
    quantum_user_password  => 'quantum_user_pass',
  # Required Horizon

    secret_key             => 'dummy_secret_key',
    network_manager        => 'nova.network.manager.FlatDHCPManager',
    fixed_range            => '10.0.0.0/24',
    floating_range         => '172.16.0.64/25',
    create_networks        => true,
    multi_host             => true,
    db_host                => '127.0.0.1',
    db_type                => 'mysql',
    mysql_account_security => true,
    # TODO - this should not allow all
    allowed_hosts          => '%',
    # Keystone
    keystone_admin_tenant  => 'admin',
    # Glance
    glance_api_servers     => '127.0.0.1:9292',
    purge_nova_config      => false,
    rabbit_password        => 'rabbit_password',
    rabbit_user            => 'nova',
    # Horizon
    cache_server_ip        => '127.0.0.1',
    cache_server_port      => '11211',
    swift                  => false,
    quantum                => false,
    horizon_app_links      => undef,
    # Genera
    verbose                => 'True',
    export_resources       => false,
  }

#  # set up a quantum server
  class { 'quantum':
    rabbit_user     => 'nova',
    rabbit_password => 'rabbit_password',
    sql_connection  => "mysql://quantum:quantum_db_pass@localhost/quantum?charset=utf8",
  }

  class { 'quantum::server':
    keystone_password => 'quantum_user_pass',
  }

  class { 'quantum::plugins::ovs':
    sql_connection      => "mysql://quantum:quantum_db_pass@localhost/quantum?charset=utf8",
    tenant_network_type => 'gre',
    # I need to know what this does...
    local_ip            => '10.0.0.1',
  }

  class { 'nova::network::quantum':
  #$fixed_range,
    quantum_admin_password    => 'quantum_user_pass',
  #$use_dhcp                  = 'True',
  #$public_interface          = undef,
    quantum_connection_host   => 'localhost',
    quantum_auth_strategy     => 'keystone',
    quantum_url               => 'http://172.16.0.3:9696',
    quantum_admin_tenant_name => 'services',
    quantum_admin_username    => 'quantum',
    quantum_admin_auth_url    => 'http://172.16.0.3:35357/v2.0'
  }

  package { 'python-cliff':
    ensure => present,
  }

  class { 'openstack::auth_file':
    admin_password       => 'ChangeMe',
    keystone_admin_token => 'service_token',
    controller_node      => '127.0.0.1',
    admin_tenant         => 'admin',
  }

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }
}

node /cinder/ {


  class { 'cinder':
    rabbit_password => 'rabbit_password',
    rabbit_host     => '172.16.0.3',
    sql_connection  => 'mysql://cinder:cinder_db_pass@172.16.0.3/cinder?charset=utf8',
    verbose         => 'True',
  }

  class { 'cinder::volume': }

  class { 'cinder::volume::iscsi': }

}




node /nova-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

#  class { 'nova::volume': enabled => true }
#  class { 'nova::volume::iscsi': }

  class { 'openstack::nova::controller':
    public_address     => '172.16.0.5',
    public_interface   => 'eth1',
    private_interface  => 'eth2',
    db_host            => '172.16.0.8',
    rabbit_password    => 'changeme',
    nova_user_password => 'nova_password',
    nova_db_password   => 'nova_password',
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    verbose            => 'True',
    multi_host         => true,
    glance_api_servers => '172.16.0.6:9292',
    keystone_host      => '172.16.0.7',
    #floating_range          => $floating_network_range,
    #fixed_range             => $fixed_network_range,
  }

  class { 'openstack::horizon':
    secret_key            => 'dummy_secret_key',
    cache_server_ip       => '127.0.0.1',
    cache_server_port     => '11211',
    swift                 => false,
    quantum               => false,
    horizon_app_links     => undef,
    keystone_host         => '172.16.0.7',
    keystone_default_role => 'Member',
  }

  class { 'openstack::auth_file':
    admin_password       => 'ChangeMe',
    keystone_admin_token => 'service_token',
    controller_node      => '172.16.0.7',
    admin_tenant         => 'admin',
  }

}

node /compute/ {

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

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

  # External lookups.
  # $rabbit_connection_hash = collect_rabbit_connection('ipaddress_eth1', 'architecture=amd64')
  # $nova_db_addr = collect_nova_db_connection('ipaddress_eth1', 'architecture=amd64')
  # $vnc_proxy_addr = unique(query_nodes('Class[nova::vncproxy]', 'ipaddress_eth1'))
  # $glance_api_addr = unique(query_nodes('Class[glance::api]', 'ipaddress_eth1'))

  class { 'openstack::compute':
    internal_address   => $::ipaddress_eth1,
    libvirt_type       => 'qemu',
    sql_connection     => 'mysql://nova:nova_db_pass@172.16.0.3/nova',
    #multi_host         => true,
    nova_user_password => 'nova_user_pass',
    rabbit_host        => '172.16.0.3',
    rabbit_password    => 'rabbit_password',
    glance_api_servers => ["172.16.0.3:9292"],
    vncproxy_host      => '172.16.0.3',
    vnc_enabled        => true,
    verbose            => true,
  }

  class { 'openstack::cinder':
    sql_connection     => 'mysql://cinder:cinder_db_pass@172.16.0.3/cinder',
    rabbit_host        => '172.16.0.3',
    rabbit_password    => 'rabbit_password',
    volume_group       => 'precise64',
  }

  # manual steps
  # apt-get update
  # apt-get upgrade
  # apt-get -y install linux-headers-3.2.0-23-generic
  # apt-get -y install quantum-plugin-openvswitch-agent
  # apt-get -y install openvswitch-datapath-dkms-source
  # module-assistant auto-install openvswitch-datapath
  # service openvswitch-switch restart

  class { 'quantum':
    verbose         => 'True',
    debug           => 'True',
    rabbit_host     => '172.16.0.3',
    rabbit_user     => 'nova',
    rabbit_password => 'rabbit_password',
    sql_connection  => "mysql://quantum:quantum_db_pass@172.16.0.3/quantum?charset=utf8",
  }

  class { 'quantum::agents::ovs':
    bridge_uplinks => ['br-virtual:eth2'],
  }

  class { 'quantum::agents::dhcp': }

  class { 'nova::compute::quantum': }

  class { 'nova::network::quantum':
  #$fixed_range,
    quantum_admin_password    => 'quantum_user_pass',
  #$use_dhcp                  = 'True',
  #$public_interface          = undef,
    quantum_connection_host   => '172.16.0.3',
    quantum_auth_strategy     => 'keystone',
    quantum_url               => 'http://172.16.0.3:9696',
    quantum_admin_tenant_name => 'services',
    quantum_admin_username    => 'quantum',
    quantum_admin_auth_url    => 'http://172.16.0.3:35357/v2.0'
  }

  nova_config {
    'linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'linuxnet_ovs_integration_bridge': value => 'br-int';
  }

}

node /devstack/ {

  class { 'devstack': }

}

node default {
  notify { $clientcert: }
}
