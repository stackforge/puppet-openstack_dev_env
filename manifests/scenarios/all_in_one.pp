#
# deploys a single all in one installation
# uses variables set in site.pp
#
#
node /openstack-all/ {

  keystone_config {
    'DEFAULT/log_config': ensure => absent,
  }

  class { 'openstack::test_file':
    quantum => $use_quantum,
  }

  # create a test volume on a loopback device for testing
  class { 'cinder::setup_test_volume': } -> Service<||>

  include 'apache'

  class { 'openstack::all':
    public_address          => $ipaddress_eth1,
    internal_address        => $ipaddress_eth1,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    mysql_root_password     => $mysql_root_password,
    secret_key              => $secret_key,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $admin_token,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    cinder_user_password    => $cinder_user_password,
    cinder_db_password      => $cinder_db_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    libvirt_type            => $libvirt_type,
    floating_range          => $floating_network_range,
    fixed_range             => $fixed_network_range,
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    quantum                 => $use_quantum,
    #vncproxy_host           => $ipaddress_eth1,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }

  # TODO not sure why this is required
  # this has a bug, and is constantly added to the file
  Package['libvirt'] ->
  file_line { 'quemu_hack':
    ensure => present,
    line   => 'cgroup_device_acl = [
   "/dev/null", "/dev/full", "/dev/zero",
   "/dev/random", "/dev/urandom",
   "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
   "/dev/rtc", "/dev/hpet", "/dev/net/tun",]',
    path   => '/etc/libvirt/qemu.conf',
  } ~> Service['libvirt']

}
