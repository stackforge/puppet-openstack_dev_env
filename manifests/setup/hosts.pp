#
# specify a connection to the hardcoded puppet master
#
host {
  'puppet':              ip => '172.16.0.2';
  'openstackcontroller': ip => '172.16.0.3';
  'compute1':            ip => '172.16.0.4';
  'compute2':            ip => '172.16.0.14';
  'novacontroller':      ip => '172.16.0.5';
  'glance':              ip => '172.16.0.6';
  'keystone':            ip => '172.16.0.7';
  'mysql':               ip => '172.16.0.8';
  'cinderclient':        ip => '172.16.0.9';
  'quantumagent':        ip => '172.16.0.10';
}

group { 'puppet':
  ensure => 'present',
}

# lay down a file that you run run for testing
file { '/root/run_puppet.sh':
  content =>
"#!/bin/bash
puppet apply --modulepath /tmp/vagrant-puppet/modules-0/ --certname ${clientcert} /tmp/vagrant-puppet/manifests/site.pp"
}
