require 'puppetlabs/os_tester/system'
require 'puppetlabs/os_tester/vagrant'

module Puppetlabs
  module OsTester
    # swift deployment methods
    module Swift

      include Puppetlabs::OsTester::System
      include Puppetlabs::OsTester::Vagrant

      def swift_nodes
        [
         'swift_storage_1',
         'swift_storage_2',
         'swift_storage_3',
         'swift_proxy',
         'swift_keystone'
        ]
      end

      def destroy_swift_vms
        puts "About to destroy all swift vms..."
        swift_nodes.each do |x|
          cmd_system("vagrant destroy #{x} --force")
        end
        puts "Destroyed all swift vms"
        begin
          on_box('puppetmaster', 'export RUBYLIB=/etc/puppet/modules-0/ruby-puppetdb/lib/; puppet query node --only-active --deactivate --puppetdb_host=puppetmaster.puppetlabs.lan --puppetdb_port=8081 --config=/etc/puppet/puppet.conf --ssldir=/var/lib/puppet/ssl --certname=puppetmaster.puppetlabs.lan')
          on_box('puppetmaster', 'rm /var/lib/puppet/ssl/*/swift*;rm /var/lib/puppet/ssl/ca/signed/swift*;')
        rescue BoxNotCreated
        end
      end

      # deploys a 3 node swift cluster in parallel
      def deploy_swift_cluster
        vagrant_command('up', 'swift_keystone')
        parallel_provision(
          [
           'swift_storage_1',
           'swift_storage_2',
           'swift_storage_3'
          ]
        )
        vagrant_command('up', 'swift_proxy')
        parallel_provision(
          [
           'swift_storage_1',
           'swift_storage_2',
           'swift_storage_3'
          ]
        )
      end

      # test that our swift cluster if functional
      def test_swift
        on_box('swift_proxy', 'ruby /tmp/swift_test_file.rb;exit $?')
      end

      # deploys a puppetmaster. this is required for deploying swift
      def deploy_puppetmaster
        vagrant_command('up', 'puppetmaster')
      end

    end
  end
end
