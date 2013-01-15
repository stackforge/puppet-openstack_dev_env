require 'puppetlabs/os_tester/system'
require 'puppetlabs/os_tester/vagrant'

module Puppetlabs
  module OsTester
    # given a pull request, return true if we should test it.
    # this means that is can be merged, and has a comment where one of the admin users

    module Openstack

      include Puppetlabs::OsTester::System
      include Puppetlabs::OsTester::Vagrant

      # deplpoy a controller/compute setup
      def deploy_two_node
        ['openstack_controller', 'compute1'].each do |vm|
          vagrant_command('up', vm)
        end
      end

      # Test a controller compute setup.
      # deletes all VMs in the current Vagrant project before
      # building a 2 node openstack environment and firing off
      # an integration test.
      #
      # == Parameters:
      #   oses::
      #     A list of operatingsystems that should be tested on.
      #
      # == Returns:
      #   TODO document
      def test_two_node(oses = [])
        require 'yaml'
        #Rake::Task['openstack:setup'.to_sym].invoke
        oses.each do |os|
          update_vagrant_os(os)
          cmd_system('vagrant destroy -f')
          deploy_two_node
          # I should check this to see if the last line is cirros
          on_box('openstack_controller', 'sudo bash /tmp/test_nova.sh;exit $?')
        end
      end

      # print a hash of all of the contributors
      # == Parameters:
      #   repos_i_care_about::
      #     An Array that specifies a list of repos to check the contributors for.
      #
      # == Returns:
      #    A hash that maps a user to a hash that contains its :email
      #    and a list of the specified repos that they have
      #    contribited to
      #
      def contributor_hash(
        repos_i_care_about = ['nova', 'glance', 'openstack', 'keystone', 'swift', 'horizon', 'cinder']
      )
        contributors = {}
        each_repo do |module_name|
          if repos_i_care_about.include?(module_name)
            logs = git_cmd('log --format=short', print=false)
            user_lines = logs.select {|x| x =~ /^Author:\s+(.*)$/ }
            user_lines.collect do |x|
              if x =~ /^Author:\s+(.*)?\s+<((\S+)@(\S+))>$/
                unless ['root', 'vagrant', 'Dan'].include?($1)
                  if contributors[$1]
                    contributors[$1][:repos] = contributors[$1][:repos] | [module_name]
                  else
                    contributors[$1] = {:email => $2, :repos => [module_name] }
                  end
                else
                  # trimming out extra users
                end
              else
                puts "Skipping unexpected line #{x}"
              end
            end
          end
        end
        contributors
      end
    end
  end
end

