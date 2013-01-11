#
# this file contains instructions for installing
# a multi-role deployments
#

#### controller/compute mode settings ####
$mysql_host    = '172.16.0.8'
$keystone_host = '172.16.0.7'
$glance_host   = '172.16.0.6'
$nova_host     = '172.16.0.5'

node /mysql/ {

  class { 'openstack::db::mysql':
    mysql_root_password  => $mysql_root_password,
    keystone_db_password => $keystone_db_password,
    glance_db_password   => $glance_db_password,
    nova_db_password     => $nova_db_password,
    cinder_db_password   => $cinder_db_password,
    quantum_db_password  => $quantum_db_password,
    allowed_hosts        => $allowed_hosts,
  }

}

node /^keystone/ {

  # TODO keystone logging seems to be totally broken in folsom
  # this can be removed once it starts working
  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  class { 'openstack::keystone':
    db_host               => $mysql_host,
    db_password           => $keystone_db_password,
    admin_token           => $admin_token,
    admin_email           => $admin_email,
    admin_password        => $admin_password,
    glance_user_password  => $glance_user_password,
    nova_user_password    => $nova_user_password,
    cinder_user_password  => $cinder_user_password,
    quantum_user_password => $quantum_user_password,
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

node /nova-controller/ {

  # deploy a script that can be used to test nova
  class { 'openstack::test_file': }

  class { 'openstack::nova::controller':
    public_address     => '172.16.0.5',
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    db_host            => '172.16.0.8',
    rabbit_password    => $rabbit_password,
    nova_user_password => $nova_user_password,
    nova_db_password   => $nova_db_password,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    verbose            => $verbose,
    multi_host         => true,
    glance_api_servers => '172.16.0.6:9292',
    keystone_host      => '172.16.0.7',
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
    keystone_host         => '172.16.0.7',
    keystone_default_role => 'Member',
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $admin_token,
    controller_node      => '172.16.0.7',
  }

}

node /nova-compute/ {
  fail('nova compute node has not been defined')
}

node /cinder/ {
  fail('the individual cinder role is not fully tested yet..')

  class { 'cinder':
    rabbit_password => $rabbit_password,
    # TODO what about the rabbit user?
    rabbit_host     => $openstack_controller,
    sql_connection  => "mysql://cinder:${cinder_db_password}@${openstack_controller}/cinder?charset=utf8",
    verbose         => $verbose,
  }

  class { 'cinder::volume': }

  class { 'cinder::volume::iscsi': }

}
