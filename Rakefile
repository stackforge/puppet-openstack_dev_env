require 'yaml'
require 'rubygems'


def cmd_system (cmd)
  result = system cmd
  raise(RuntimeError, $?) unless $?.success?
  result
end

def git_cmd(cmd)
  command = 'git ' + cmd
  Open3.popen3(*command) do |i, o, e, t|
    raise StandardError, e.read unless (t ? t.value : $?).success?
    o.read.split("\n")
  end
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
    require 'vagrant'
    env = Vagrant::Environment.new(:cwd => File.dirname(__FILE__), :ui_class => Vagrant::UI::Colored)

    puts "About to destroy all vms..."
    env.cli('vagrant destroy -f')
    puts "Destroyed all vms"
  end

  desc 'deploys the entire environment'
  task :deploy_two_node do
    require 'vagrant'
    env = Vagrant::Environment.new(:cwd => File.dirname(__FILE__), :ui_class => Vagrant::UI::Colored)
    build(:openstack_controller, env)
    build(:compute1, env)
  end

end


remote_name = 'bodepd'

namespace :git do

  cwd = File.expand_path(File.dirname(__FILE__))

  desc 'for all repos in the module directory, add a read/write remote'
  task :dev_setup do

    each_repo do |module_name|
      # need to handle more failure cases
      remotes = git_cmd('remote')
      if remotes.include?(remote_name)
        puts "Did not have to add remote #{remote_name} to #{module_name}"
      elsif ! remotes.include?('origin')
        raise(Exception, "Repo #{module_name} has no remote called origin, failing")
      else
        remote_url = git_cmd('remote show origin').detect {|x| x =~ /\s+Push\s+URL: / }
        if remote_url =~ /(git|https?):\/\/(.+)\/(.+)?\/(.+)/
          url = "git@#{$2}:#{remote_name}/#{$4}"
        else
          puts "remote_url #{remote_url} did not have the expected format. weird..."
        end
        puts "Adding remote #{remote_name} as #{url}"
        git_cmd("remote add #{remote_name} #{url}")
      end
    end
  end

  desc 'pull the latest version of all code'
  task :pull_all do
    each_repo do |module_name|
      puts "Pulling repo: #{module_name}"
      puts '  ' + git_cmd('pull').join("\n  ")
    end
  end

  desc 'shows the current state of code that has not been commited'
  task :status_all do
    each_repo do |module_name|
      status = git_cmd('status')
      if status.include?('nothing to commit (working directory clean)')
        puts "Module #{module_name} has not changed" if verbose
      else
        puts "Uncommitted changes for: #{module_name}"
        puts "  #{status.join("\n  ")}"
      end
    end
  end

  desc 'make sure that the current version from the module file matches the last tagged version'
  task :check_tags do
    # I need to be able to return this as a data structure
    # when I start to do more complicated things like
    # automated releases, I will need this data
    each_repo do |module_name|
      require 'puppet'
      modulefile = File.join(Dir.getwd, 'Modulefile')
      if File.exists?(modulefile)
        print module_name
        metadata  = ::Puppet::ModuleTool::Metadata.new
        ::Puppet::ModuleTool::ModulefileReader.evaluate(metadata, modulefile)
        print ':' + metadata.version
        branch_output = git_cmd('branch')
        if branch_output.first =~ /\* (.+)/
          puts ":#{$1}"
          puts '  ' + git_cmd("log #{metadata.version}..HEAD --oneline").join("\n  ")
          puts ''
        else
          puts '  ' + branch_output.join("\n  ")
        end
      else
        puts "#{module_name} does not have a Modulefile"
      end
    end
  end

  task :check_sha_all do
    each_repo do |module_name|
      print module_name + ':'
      puts git_cmd('rev-parse HEAD --quiet')
    end
  end

  desc 'prints the total number of people that have contributed to all projects.'
  task :num_contributors do
    puts contributor_hash.size
  end

  desc 'print the names of all contributors (and what projects they contributed to'
  task :list_contributors do
    contributor_hash.each do |k, v|
      puts "#{k}:#{v[:repos].inspect}"
    end
  end
end

namespace :test do

  desc 'test openstack with basic test script'
  task 'two_node' do
    #Rake::Task['openstack:setup'.to_sym].invoke
    Rake::Task['openstack:deploy_two_node'.to_sym].invoke
    on_box('openstack_controller', 'sudo bash /tmp/test_nova.sh;exit $?')
  end

  task :test do
    on_box('openstack_controller', 'sudo bash /tmp/foo.sh')
  end
end

def contributor_hash
  repos_i_care_about = ['nova', 'glance', 'openstack', 'keystone', 'swift', 'horizon', 'cinder']
  contributors = {}
  each_repo do |module_name|
    if repos_i_care_about.include?(module_name)
      logs = git_cmd('log --format=short')
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


def each_repo(&block)
  require 'librarian/puppet'
  require 'librarian/puppet/source/git'
  # create a manifest
  # TODO replace this to use librarian puppet
  env = Librarian::Puppet::Environment.new()
  # this is the lock file, so it assumes that install has been run
  env.lock.manifests.each do |manifest|
    # I only care about git sources
    if manifest.source.is_a? Librarian::Puppet::Source::Git
      module_name = manifest.name.split('/', 2)[1]
      module_path = File.join(env.install_path,module_name)
      if File.directory?(module_path)
        Dir.chdir(module_path) do
          yield module_name
        end
      else
        puts "Module directory #{module_path} does not exist... How strange."
      end
    else
      puts "Found a non-git manifest: #{manifest.class}, ignoring"
    end
  end
end
