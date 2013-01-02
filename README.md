# sharable openstack puppet dev environment

This project contains everything that you need to rebuild the
same development environment that I built initilaly for the
folsom implementation of the openstack puppet modules.

# build status for all projects:


* OpenStack: [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-openstack.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-openstack)
* Nova:      [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-nova.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-nova)
* Glance:    [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-glance.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-glance)
* Keystone:  [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-keystone.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-keystone)
* Horizon:   [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-horizon.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-horizon)
* Swift:     [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-swift.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-swift)
* Cinder:    [![Unit Test Status](https://secure.travis-ci.org/puppetlabs/puppetlabs-cinder.png?branch=master)](http://travis-ci.org/puppetlabs/puppetlabs-cinder)

# prereqs

1. Ensure that you have rake as well as rubygems installed

2. install vagranat and dependencies:

vagrant should be installed

    > gem install vagrant

virtualbox should be installed

3. Install librarian-puppet.

    > gem install librarian-puppet

4. it is strongly recommended that you set up a proxy (like squid!) to speed up perforance
of package installation.

# project contents

This project contains the following files

Vagrantfile - used to specify the virtual machines that vagrant can use to
spin up test openstack environments.

Rakefile - stores tasks that can be used to build out openstack environments

Puppetfile - used by librarian puppet to install the required modules

manifests/hosts.pp

stores basic host setup (apt setup, configured to use a proxy)

manifests/site.pp

# installing module deps

    # cd in to the project directory
    > librarian-puppet install

# getting started

Configure the hosts.pp file to point to your apt cache
(or comment out the proxy host and port from the following resource)

    class { 'apt':
      proxy_host => '172.16.0.1',
      proxy_port => '3128',
    }

Too see a list of the virtual machines that are managed by vagrant, run

    > vagrant status
    devstack                 not created
    openstack_controller     not created
    compute1                 not created
    nova_controller          not created
    glance                   not created
    keystone                 not created
    mysql                    not created

To see a list of all available rake tasks, run:
(rake tasks have not yet been defined)

    > rake -t

Deploy a controller and a compute node:

    > vagrant up openstack_controller
    # wait until this finishes
    > vagrant up compute1
    # wait until this finishes

Once these finish successfully, login to the controller:

    > vagrant ssh openstack_controller

Run the following test script:

    [controller]# bash /tmp/test_nova.sh

