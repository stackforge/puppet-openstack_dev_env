#
# This document serves as an example of how to deploy
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
    allowed_hosts        => ['keystone', 'glance', 'novacontroller', 'compute1', '%'],
  }

}

node /keystone/ {

  nova_config {
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
    public_interface       => 'eth0',
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
  # Required Horizon
    secret_key             => 'dummy_secret_key',
    network_manager        => 'nova.network.manager.FlatDHCPManager',
    fixed_range            => '10.0.0.0/24',
    floating_range         => '172.16.2.0/24',
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
    # Horizon
    cache_server_ip        => '127.0.0.1',
    cache_server_port      => '11211',
    swift                  => false,
    quantum                => false,
    horizon_app_links      => undef,
    # Genera
    verbose                => false,
    export_resources       => false,
  }

  class { 'openstack::auth_file':
    admin_password       => 'ChangeMe',
    keystone_admin_token => 'service_token',
    controller_node      => '127.0.0.1',
    admin_tenant         => 'admin',
  }
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

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

  # External lookups.
  # $rabbit_connection_hash = collect_rabbit_connection('ipaddress_eth1', 'architecture=amd64')
  # $nova_db_addr = collect_nova_db_connection('ipaddress_eth1', 'architecture=amd64')
  # $vnc_proxy_addr = unique(query_nodes('Class[nova::vncproxy]', 'ipaddress_eth1'))
  # $glance_api_addr = unique(query_nodes('Class[glance::api]', 'ipaddress_eth1'))

  class { 'openstack::compute':
    public_interface   => 'eth1',
    private_interface  => 'eth2',
    internal_address   => $::ipaddress_eth1,
    libvirt_type       => 'qemu',
    sql_connection     => 'mysql://nova:nova_db_pass@172.16.0.3/nova',
    fixed_range        => '10.0.0.0/24',
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => true,
    nova_user_password => 'nova_user_pass',
    rabbit_host        => '172.16.0.3',
    rabbit_password    => 'rabbit_password',
    glance_api_servers => ["172.16.0.3:9292"],
    vncproxy_host      => '172.16.0.3',
    vnc_enabled        => true,
    verbose            => true,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes'
  }
}

node /devstack/ {

  class { 'devstack': }

}

node /master/ {
  # we assume the razor service has already been started here.
  rz_image { 'ubuntu_precise':
    ensure  => present,
    type    => 'os',
    source  => '/vagrant/ubuntu-12.04-server-amd64.iso',
    version => '12.04',
    tag     => ['os','pe']
  }

  file { '/opt/razor/image/puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz':
    source => '/vagrant/puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz',
    tag    => ['pe']
  }

  file { '/opt/razor/lib/project_razor/model':
    ensure  => 'file',
    source  => '/vagrant/model',
    recurse => true,
    tag     => ['os','pe']
  } -> Rz_model<| |>

  rz_model { 'precise_controller_os':
    ensure      => present,
    image       => 'ubuntu_precise',
    metadata    => {'domainname' => 'puppetlabs.vm', 'hostname_prefix' => 'openstack-controller', 'rootpassword' => 'openstack' },
    template    => 'ubuntu_precise_puppet',
    tag         => ['os']
  }

  rz_model { 'precise_compute_os':
    ensure      => present,
    image       => 'ubuntu_precise',
    metadata    => {'domainname' => 'puppetlabs.vm', 'hostname_prefix' => 'openstack-compute', 'rootpassword' => 'openstack' },
    template    => 'ubuntu_precise_puppet',
    tag         => ['os']
  }

  rz_policy { 'controller_os':
    ensure   => present,
    broker   => none,
    model    => 'precise_controller_os',
    enabled  => true,
    tags     => ['memsize_500MiB'],
    template => 'linux_deploy',
    tag      => ['os']
  }

  rz_policy { 'compute_os':
    ensure   => present,
    broker   => none,
    model    => 'precise_compute_os',
    enabled  => true,
    tags     => ['memsize_2017MiB'],
    template => 'linux_deploy',
    tag      => ['os']
  }

  rz_model { 'precise_controller_pe':
    ensure      => present,
    image       => 'ubuntu_precise',
    metadata    => {'domainname' => 'puppetlabs.vm', 'hostname_prefix' => 'openstack-controller', 'rootpassword' => 'openstack' },
    template    => 'ubuntu_precise_pe',
    tag         => ['pe']
  }

  rz_model { 'precise_compute_pe':
    ensure      => present,
    image       => 'ubuntu_precise',
    metadata    => {'domainname' => 'puppetlabs.vm', 'hostname_prefix' => 'openstack-compute', 'rootpassword' => 'openstack' },
    template    => 'ubuntu_precise_pe',
    tag         => ['pe']
  }

  rz_policy { 'controller_pe':
    ensure   => present,
    broker   => none,
    model    => 'precise_controller_pe',
    enabled  => true,
    tags     => ['memsize_500MiB'],
    template => 'linux_deploy',
    tag      => ['pe']
  }

  rz_policy { 'compute_pe':
    ensure   => present,
    broker   => none,
    model    => 'precise_compute_pe',
    enabled  => true,
    tags     => ['memsize_2017MiB'],
    template => 'linux_deploy',
    tag      => ['pe']
  }
}

node default {
  notify { $clientcert: }
}
