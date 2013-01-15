require 'puppetlabs/os_tester/system'

module Puppetlabs
  module OsTester
    # vagrant helper methods
    module Vagrant

      include Puppetlabs::OsTester::System

      class BoxNotCreated < Exception
      end

      # run a vagrant command
      # Parameters:
      #   cmd::
      #     vagrant command that should be run.
      #   box::
      #     box that the command should be applied to.
      # Return:
      #  TODO - figire out the return
      def vagrant_command(cmd, box='')
        require 'vagrant'
        env = ::Vagrant::Environment.new(:ui_class => ::Vagrant::UI::Colored)
        puts "Running #{cmd} on #{box ? box : 'all'}"
        env.cli(cmd, box)
      end

      # run a command on an image as sudo. return the output
      # Parameters:
      #   box::
      #     box that the command should be applied to.
      #   cmd::
      #     command that should be run as sudo on the box.
      # Returns:
      #   stdout from the executed ssh command.
      #
      # TODO make these two method argument lists consistent
      def on_box (box, cmd)
        require 'vagrant'
        env = ::Vagrant::Environment.new(:ui_class => ::Vagrant::UI::Colored)
        raise("Invalid VM: #{box}") unless vm = env.vms[box.to_sym]
        raise(BoxNotCreated, "VM: #{box} was not already created") unless vm.created?
        ssh_data = ''
        #vm.channel.sudo(cmd) do |type, data|
        vm.channel.sudo(cmd) do |type, data|
          ssh_data = data
          env.ui.info(ssh_data.chomp, :prefix => false)
        end
        ssh_data
      end

      # destroy all vagrant images
      def destroy_all_vms
        puts "About to destroy all vms..."
        vagrant_command('destroy -f')
        puts "Destroyed all vms"
      end

      # provision a list of vms in parallel
      def parallel_provision(vms)
        require 'thread'
        results = {}
        threads = []
        queue = Queue.new
        vms.each  {|vm| vagrant_command(['up', '--no-provision'], vm) }
        vms.each do |vm|
          threads << Thread.new do
            result = cmd_system("vagrant provision #{vm}")
            # I cant use a regular vagrant call
            #result = vagrant_command('provision', vm)
            queue.push({vm => {'result' => result}})
          end
        end
        threads.each do |aThread|
          begin
            aThread.join
          rescue Exception => spawn_err
            puts("Failed spawning vagrant provision thread: #{spawn_err}")
          end
        end
        until queue.empty?
          provision_results = queue.pop
          results.merge!(provision_results)
        end
        results
      end

      # update the operatingsystem in the vagrant conig file
      def update_vagrant_os(os)
        cfg = File.join(base_dir, 'config.yaml')
        yml = YAML.load_file(cfg).merge({'operatingsystem' => os})
        File.open(cfg, 'w') {|f| f.write(yml.to_yaml) }
      end
    end
  end
end
