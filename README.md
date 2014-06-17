E
# sharable openstack puppet dev environment

This project contains everything that you need to rebuild the
same development environment that I built initilaly for the
folsom implementation of the openstack puppet modules.

# prereqs

1. Ensure that you have rubygems installed

2. install vagrant and dependencies:

vagrant should be installed (the latest version of vagrant is generally available as a package)

    > gem install vagrant

virtualbox should be installed

3. Install librarian-puppet-simple.

    > gem install librarian-puppet-simple

3. it is strongly recommended that you set up a proxy (like squid!) to speed up perforance
of package installation. If you do not use a proxy, you need to change some settings in
your site manifest.

# project contents

This project contains the following files

Vagrantfile
  specifies virtual machines that build openstack test/dev environments.

Puppetfile
  used by librarian puppet to install the required modules

manifests/setup/hosts.pp
  stores basic host setup (ip addresses for vagrant targets)

manifests/setup/percise64.pp
  stores apt setup, configured to use a proxy, and folsom package pointer(s)

manifests/setup/centos.pp
  stores yum setup, configuration for a local yum repo machine, and folsom package pointer(s)

manifests/site.pp
  stores site manifests for configuring openstack

# installing module deps

    # cd in to the project directory
    > librarian-puppet install

# getting started

Configure the precise64.pp file to point to your apt cache
(or comment out the proxy host and port from the following resource)
(similar for centos.pp)

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

The best maintained examples are for a two node install
based on a compute and controller.

Deploy a controller and a compute node:

    > vagrant up openstack_controller
    # wait until this finishes
    > vagrant up compute1
    # wait until this finishes

Once these finish successfully, login to the controller:

    > vagrant ssh openstack_controller

Run the following test script:

    [controller]# bash /tmp/test_nova.sh

