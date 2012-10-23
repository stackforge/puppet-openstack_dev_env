require 'yaml'
require 'rubygems'


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

# returns an array of the stdout lines with leading and trailing whitespace removed
def get_stdout(cmd)
  # need to do this smarter...
  `#{cmd}`.split("\n").collect {|x| x.strip }
end

namespace :paven do

  cwd = File.expand_path(File.dirname(__FILE__))

  desc 'for all repos in the module directory, add a read/write remote'
  task :dev_setup do

    each_repo do |repo|
      # need to handle more failure cases
      remotes = repo.remote_names
      if remotes.include?(remote_name)
        puts "Did not have to add remote #{remote_name} to #{File.basename(repo.path)}"
      elsif ! remotes.include?('origin')
        raise(Exception, "The repo #{File.basename(repo.path)} does not have a remote called origin, failing")
      else
        url = repo.remote_push_url('origin').gsub(/(git|https?):\/\/(.+)\/(.+)?\/(.+)/) do
          "git@#{$2}:#{remote_name}/#{$4}"
        end
        puts "Adding remote #{remote_name} as #{url}"
        repo.add_remote(remote_name, url)
      end
    end
  end

  desc 'pull the latest version of all code'
  task :pull_all do
    each_repo do |repo|
      puts "Pulling repo: #{File.basename(repo.path)}"
      puts '  ' + repo.pull.join("\n  ")
    end
  end

  desc 'shows the current state of code that has not been commited'
  task :status_all do
    each_repo do |repo|
      status = repo.status
      if status.include?('nothing to commit (working directory clean)')
        puts "Module #{File.basename(repo.path)} has not changed" if verbose
      else
        puts "Uncommitted changes for: #{File.basename(repo.path)}"
        puts "  #{get_stdout('git status').join("\n  ")}"
      end
    end
  end

  desc 'make sure that the current version from the module file matches the last tagged version'
  task :check_tags do
    # I need to be able to return this as a data structure
    # when I start to do more complicated things like
    # automated releases, I will need this data
    each_repo do |repo|
      require 'puppet'
      modulefile = File.join(repo.path, 'Modulefile')
      if File.exists?(modulefile)
        print File.basename(repo.path)
        metadata  = ::Puppet::ModuleTool::Metadata.new
        ::Puppet::ModuleTool::ModulefileReader.evaluate(metadata, modulefile)
        print ':' + metadata.version
        branch_output = get_stdout('git branch')
        if branch_output.first =~ /\* (.+)/
          puts ":#{$1}"
          git_cmd = %W(log #{metadata.version}..HEAD --oneline)
          puts '  ' + repo.git_cmd(git_cmd).join("\n  ")
        else
          puts '  ' + branch_output.join("\n  ")
        end
      else
        puts "#{File.basename(repo.path)} does not have a Modulefile"
      end
    end
  end

  task :check_sha do
    each_repo do |repo|
      print File.basename(repo.path) + ':'
      puts repo.current_commit_hash
    end
  end


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
      yield Librarian::Source::Git::Repository.new(env, module_path)
    else
      puts "Found a non-git manifest: #{manifest.class}, ignoring"
    end
  end
end
