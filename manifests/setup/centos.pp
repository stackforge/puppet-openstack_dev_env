import 'hosts.pp'

file { '/etc/yum.repos.d':
  ensure => directory,
}

file { '/tmp/setup_epel.sh':
  content =>
'
#!/bin/bash
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6*.rpm'
}

exec { '/bin/bash /tmp/setup_epel.sh':
  refreshonly => true,
  subscribe   => File['/tmp/setup_epel.sh']
}

ini_setting { 'enable_epel_testing':
  ensure  => present,
  path    => '/etc/yum.repos.d/epel-testing.repo',
  section => 'epel-testing',
  setting => 'enabled',
  value   => '1',
  require => Exec['/bin/bash /tmp/setup_epel.sh'],
}

ini_setting { 'yum_proxy':
  ensure  => present,
  path    => '/etc/yum.conf',
  section => 'main',
  setting => 'proxy',
  value   => 'http://172.16.0.1:3128',
  require => Exec['/bin/bash /tmp/setup_epel.sh'],
}
