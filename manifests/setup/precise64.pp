#import 'hosts.pp'

#
# This puppet manifest is already applied first to do some environment specific things
#

$openstack_version  = hiera('openstack_version', 'folsom')

apt::source { 'openstack_cloud_archive':
  location          => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
  release           => "precise-updates/${openstack_version}",
  repos             => "main",
  required_packages => 'ubuntu-cloud-keyring',
}

#
# configure apt to use my squid proxy
# I highly recommend that anyone doing development on
# OpenStack set up a proxy to cache packages.
#
class { 'apt':
  proxy_host => '172.16.0.1',
  proxy_port => '3128',
}

# an apt-get update is usally required to ensure that
# we get the latest version of the openstack packages
exec { '/usr/bin/apt-get update':
  require     => Class['apt'],
  refreshonly => true,
  subscribe   => [Class['apt'], Apt::Source["openstack_cloud_archive"]],
  logoutput   => true,
}

# run the apt get update before any packages are installed!
Exec['/usr/bin/apt-get update'] -> Package<||>

package { [ 'vim', 'lvm2' ]: ensure => present }

