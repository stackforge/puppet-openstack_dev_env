#
# This puppet manifest is already applied first to do some environment specific things
#

apt::ppa {"ppa:openstack-ubuntu-testing/folsom-trunk-testing": }
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
  subscribe   => [Class['apt'], Apt::Ppa["ppa:openstack-ubuntu-testing/folsom-trunk-testing"]],
  logoutput   => true,
}

#
# specify a connection to the hardcoded puppet master
#
host { 'puppet':
  ip => '172.16.0.2',
}

group { 'puppet':
  ensure => 'present',
}

# bring up the bridging interface explicitly
#exec { '/sbin/ifconfig eth2 up': }

