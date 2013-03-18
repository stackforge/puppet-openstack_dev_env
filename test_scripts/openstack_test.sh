#!/bin/bash
#
# script to build a two node openstack environment and test.
# this script is intended to be run as a jenkins parameterized build with
# the following build parameters:
#   $BUILD_ID - jenkins variables that determines the directory where the test is run
#   $operatingsystem - OS to test OS install on (accepts Redhat/Ubuntu)
#   $openstack_version - openstack version to test (accepts folsom/grizzly)
#   $test_mode type of test to run (accepts: tempest_full, tempest_smoke, puppet_openstack)
#
# # I am running it as follows:
# mkdir $BUILD_ID
# cd $BUILD_ID
# git clone git://github.com/puppetlabs/puppetlabs-openstack_dev_env
# cd puppetlabs-openstack_dev_env
# bash test_scripts/openstack_test.sh
# TODO figure out if I should add pull request support
set -e

# set testing variables
echo "operatingsystem: ${operatingsystem}" > config.yaml
if [ $openstack_version = 'grizzly' ]; then
  echo 'openstack_version: grizzly' > hiera_data/jenkins.yaml
else
  echo 'openstack_version: folsom' > hiera_data/jenkins.yaml
fi

mkdir .vendor
export GEM_HOME=`pwd`/.vendor
# install gem dependencies
bundle install
# install required modules
bundle exec librarian-puppet install
# install a controller and compute instance

# check that the VM is not currently running
# if it is, stop that VM
if VBoxManage list vms | grep openstack_controller.puppetlabs.lan; then
  VBoxManage controlvm openstack_controller.puppetlabs.lan  poweroff || true
  VBoxManage unregistervm openstack_controller.puppetlabs.lan  --delete
fi
bundle exec vagrant up openstack_controller

# check if the compute VM is running, if so stop the VM before launching ours
if VBoxManage list vms | grep compute2.puppetlabs.lan; then
  VBoxManage controlvm compute2.puppetlabs.lan  poweroff || true
   VBoxManage unregistervm compute2.puppetlabs.lan --delete
fi
bundle exec vagrant up compute2
# install tempest on the controller
bundle exec vagrant status

if [ $test_mode = 'puppet_openstack' ]; then
  # run my simple puppet integration tests
  bundle exec vagrant ssh -c 'sudo bash /tmp/test_nova.sh;exit $?' openstack_controller
elif [ $test_mode = 'tempest_smoke' ]; then
  # run the tempest smoke tests
  bundle exec vagrant ssh -c 'sudo puppet apply --certname tempest --modulepath=/etc/puppet/modules-0/ /etc/puppet/manifests/site.pp --trace --debug' openstack_controller
  # run tempest tests
  bundle exec vagrant ssh -c 'cd /var/lib/tempest/;sudo ./jenkins_launch_script.sh --smoke;' openstack_controller
elif [ $test_mode = 'tempest_full' ]; then
  bundle exec vagrant ssh -c 'cd /var/lib/tempest/;sudo ./jenkins_launch_script.sh;' openstack_controller
else
  echo "Unsupported testnode ${test_mode}, this test matrix only support tempest_smoke and puppet_openstack tests"
fi
