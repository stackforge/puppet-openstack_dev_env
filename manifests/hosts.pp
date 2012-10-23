#
# configure apt to use my squid proxy
# I highly recommend that anyone doing development on
# OpenStack set up a proxy to cache packages.
#
class { 'apt':
  proxy_host => '172.16.5.1',
  proxy_port => '3128',
}

#
# specify a connection to the hardcoded puppet master
#
host {
  'puppet':              ip => '172.16.5.2';
  'openstackcontroller': ip => '172.16.5.3';
  'compute1':            ip => '172.16.5.4';
  'novacontroller':      ip => '172.16.5.5';
  'glance':              ip => '172.16.5.6';
  'keystone':            ip => '172.16.5.7';
  'mysql':               ip => '172.16.5.8';
  'cinderclient':        ip => '172.16.5.9';
  'quantumagent':        ip => '172.16.5.10';
}

group { 'puppet':
  ensure => 'present',
}

# bring up the bridging interface explicitly
#exec { '/sbin/ifconfig eth2 up': }

node default { }
