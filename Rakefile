require 'yaml'
require 'rubygems'
require 'vagrant'

env = Vagrant::Environment.new(:cwd => File.dirname(__FILE__), :ui_class => Vagrant::UI::Colored)

def cmd_system (cmd)
  result = system cmd
  raise(RuntimeError, $?) unless $?.success?
  result
end

def on_box (box, cmd)
  cmd_system("vagrant ssh #{box} -c '#{cmd}'")
end

# bring vagrant vm with image name up
def build(instance, env)
  unless vm = env.vms[instance]
    puts "invalid VM: #{instance}"
  else
    if vm.created?
      puts "VM: #{instance} was already created"
    else
      # be very fault tolerant :)
      begin
        # this will always fail
        vm.up(:provision => true)
      rescue Exception => e
        puts e.class
        puts e
      end
    end
  end
end

namespace :openstack do

  desc 'clone all required modules'
  task :setup do
    cmd_system('librarian-puppet install')
  end

  task 'destroy' do
    puts "About to destroy all vms..."
    env.cli('vagrant destroy -f')
    puts "Destroyed all vms"
  end

  desc 'deploys the entire environment'
  task :deploy_two_node do
    build(:openstack_controller, env)
    build(:compute1, env)
  end

end
