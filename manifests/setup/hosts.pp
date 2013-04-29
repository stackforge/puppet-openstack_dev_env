#
# this manifest performs essentially environment configuration
# that needs to be run before anything is configured
#

#
# setup basic dns in /etc/hosts
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
  'swift_proxy':         ip => '172.16.0.21';
  'swift_storage_1':     ip => '172.16.0.22';
  'swift_storage_2':     ip => '172.16.0.23';
  'swift_storage_3':     ip => '172.16.0.24';
}

group { 'puppet':
  ensure => 'present',
}

# lay down a file that you run run for testing
file { '/root/run_puppet.sh':
  content =>
"#!/bin/bash
puppet apply --modulepath /etc/puppet/modules-0/ --certname ${clientcert} /etc/puppet/manifests/site.pp $*"
}

package { ['make', 'gcc']:
  ensure => present,
}

$puppet2 = str2bool(inline_template('<%= scope.lookupvar("::puppetversion") < "3.0" %>'))
if $puppet2 {
  # install hiera, to support Puppet pre 3.0
  package { ['hiera', 'hiera-puppet']:
    ensure   => present,
    provider => 'gem',
  }
}

$ruby18 = str2bool(inline_template('<%= scope.lookupvar("::rubyversion") < "1.9" %>'))
if $ruby18 {
  package { 'ruby-debug':
    ensure   => present,
    provider => 'gem',
    require  => Package[[ 'make', 'gcc']],
  }
} else {
  package { 'debugger':
    ensure   => present,
    provider => 'gem',
    require  => Package[[ 'make', 'gcc']],
  }
}

file { '/etc/puppet/hiera.yaml':
  content =>
'
---
:backends:
  - yaml
:hierarchy:
  - "%{hostname}"
  - jenkins
  - common
:yaml:
   :datadir: /etc/puppet/hiera_data'
}


package { 'wget':
  ensure => present,
}

file_line { 'wgetrc_proxy':
  ensure  => present,
  line    => "https_proxy = http://172.16.0.1:3128/",
  path    => '/etc/wgetrc',
  require => Package['wget'],
}

# not sure if this is the best place for my puppetmaster config
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

node default { }
