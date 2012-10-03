#
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#


####### shared variables ##################


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth2'
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'keystone_admin'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '10.0.0.0/24'
$floating_network_range  = '172.16.0.192/26'
# switch this to true to have all service log at verbose
$verbose                 = false
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = false


#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node /openstack-all/ {

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

  class { 'openstack::all':
    public_address          => $ipaddress_eth1,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    libvirt_type            => 'qemu',
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
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
  }

}

node /keystone/ {

  class { 'keystone':
    log_verbose    => true,
    log_debug      => true,
    sql_connection => 'mysql://keystone_admin:password@172.16.0.8/keystone',
    catalog_type   => 'sql',
  }
  class { 'keystone::roles::admin': }
}

node /controller/ {

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

  $controller_node_address  = $ipaddress_eth1
  $controller_node_public   = $controller_node_address
  $controller_node_internal = $controller_node_address


#  class { 'nova::volume': enabled => true }

#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => true,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }


}

node /compute/ {

# deploy a script that can be used to test nova
class { 'openstack::test_file': }

  # External lookups.
  $rabbit_connection_hash = collect_rabbit_connection('ipaddress_eth1', 'architecture=amd64')
  $nova_db_addr = collect_nova_db_connection('ipaddress_eth1', 'architecture=amd64')
  $vnc_proxy_addr = unique(query_nodes('Class[nova::vncproxy]', 'ipaddress_eth1'))
  $glance_api_addr = unique(query_nodes('Class[glance::api]', 'ipaddress_eth1'))

  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $ipaddress_eth1,
    libvirt_type       => 'qemu',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => true,
    sql_connection     => $nova_db_addr,
    nova_user_password => $nova_user_password,
    rabbit_host        => $rabbit_connection_hash['host'],
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => ["${glance_api_addr}:9292"],
    vncproxy_host      => $vnc_proxy_addr,
    vnc_enabled        => true,
    verbose            => $verbose,
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
