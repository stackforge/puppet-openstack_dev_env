#
# specify a connection to the hardcoded puppet master
#
host {
  'puppetmaster':        ip => '172.16.0.31', host_aliases => ['puppetmaster.puppetlabs.lan'];
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
package { ['make', 'gcc']:
  ensure => present,
} ->

# install hiera
# TODO pretty sure hiera-puppet is not installed b/c I installed the module
package { ['hiera', 'hiera-puppet', 'ruby-debug']:
  ensure   => present,
  provider => 'gem',
}

package { 'vim': ensure => present }

file { '/etc/puppet/hiera.yaml':
  content =>
'
---
:backends:
  - yaml
:hierarchy:
  - "%{hostname}"
  - common
:yaml:
   :datadir: /etc/puppet/hiera_data'
}

node /puppetmaster/ {
  Ini_setting {
    path    => '/etc/puppet/puppet.conf',
    section => 'main',
    ensure  => present,
  }

  ini_setting {'vardir':
    setting => 'vardir',
    value   => '/var/lib/puppet/',
  }
  ini_setting {'ssldir':
    setting => 'ssldir',
    value   => '/var/lib/puppet/ssl/',
  }
  ini_setting {'rundir':
    setting => 'rundir',
    value   => '/var/run/puppet/',
  }
}
