# sharable openstack puppet dev environment

This project contains everything that you need to rebuild the same development
environment that I built initilaly for the folsom implementation of the
openstack puppet modules.

# prereqs

1. Ensure that you have rake and rubygems installed

2. install Vagrant and dependencies:

vagrant 1.2.2 or later should be installed.

    > http://downloads.vagrantup.com

Virtualbox or VMware Fusion should be installed. (If you choose to use VMware
Fusion you will also need http://www.vagrantup.com/vmware#buy-now.)

    > https://www.virtualbox.org/wiki/Downloads
    > http://www.vmware.com/products/fusion/overview.html

3. Install librarian-puppet. (Some versions have bugs...kinda the luck of the draw.)

    > gem install librarian-puppet

4. It is strongly recommended that you set up a proxy (like squid!) to speed up perforance
of package installation. If you do not use a proxy, you need to change some settings in
your site manifest.

# project contents

This project contains the following files

Vagrantfile - used to specify the virtual machines that vagrant can use to
spin up test openstack environments.

Rakefile - stores tasks that can be used to build out openstack environments

Puppetfile - used by librarian puppet to install the required modules

manifests/setup/hosts.pp

stores basic host setup (ip addresses for vagrant targets)

manifests/setup/percise64.pp

stores apt setup, configured to use a proxy, and folsom package pointer(s)

manifests/setup/centos.pp

stores yum setup, configuration for a local yum repo machine, and folsom package pointer(s)

manifests/site.pp

just what you'd expect it to be.

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

You'll want to change line 131 or 133 to use the same address to configured in the
precise64.pp and/or centos.pp.

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

    > rake -T

Deploy a controller and a compute node:

    > vagrant up openstack_controller
    # wait until this finishes
    > vagrant up compute1
    # wait until this finishes

Once these finish successfully, login to the controller:

    > vagrant ssh openstack_controller

Run the following test script:

    [controller]# bash /tmp/test_nova.sh

