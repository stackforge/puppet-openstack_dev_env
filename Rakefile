require 'yaml'

def system (cmd)
  result = core_system cmd
  raise(RuntimeError, $?) unless $?.success?
  result
end

def on_box (box, cmd)
  system("vagrant ssh #{box} -c '#{cmd}'")
end

namespace :openstack_demo do

  desc 'install the puppet master with razor, dhcp, and puppetdb'
  task :install_master do

    # install razor-puppet-puppetdb-demo.git
    unless File.directory? 'razor-puppet-puppetdb-demo'
      system('git clone git://github.com/stephenrjohnson/razor-puppet-puppetdb-demo.git')
    end

    Dir.chdir('razor-puppet-puppetdb-demo/') do

      # install all module dependencies
      system('librarian-puppet install --verbose')
      raise :RuntimeError unless $?.success?
      # bring up a master
    end

  end

  desc 'start the actual puppet master'
  task :start_master do
    Dir.chdir("razor-puppet-puppetdb-demo/env/#{vagrant_env}") do
      if use_pe
        FileUtils.cp '../../../files/puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz', './'
      end
      system('vagrant up master')
    end

  end

  desc 'clone all required modules'
  task :setup do
    require 'fileutils'
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    repos = (repo_hash['repos'] || {})
    modulepath = (repo_hash['modulepath'] || default_modulepath)
    repos_to_clone = (repos['repo_paths'] || {})
    branches_to_checkout = (repos['checkout_branches'] || {})
    repos_to_clone.each do |remote, local|
      # I should check to see if the file is there?
      outpath = File.join(modulepath, local)
      if File.directory? outpath
        Dir.chdir(outpath) do
          system("git pull")
        end
      else
        system("git clone #{remote} #{outpath}")
      end
    end
    branches_to_checkout.each do |local, branch|
      Dir.chdir(File.join(modulepath, local)) do
        system("git checkout #{branch}")
      end
    end
    FileUtils.cp('manifests/site.pp', 'razor-puppet-puppetdb-demo/manifests/site.pp')
    if File.exists? "razor-puppet-puppetdb-demo/env/#{vagrant_env}/model"
      FileUtils.rm_rf "razor-puppet-puppetdb-demo/env/#{vagrant_env}/model"
    end
    FileUtils.cp_r('files/model', "razor-puppet-puppetdb-demo/env/#{vagrant_env}/model")
  end

  desc 'configure Razor to deploy openstack'
  task :configure_razor do
    Dir.chdir("razor-puppet-puppetdb-demo/env/#{vagrant_env}") do
      on_box 'master', 'sudo chown -R puppet:puppet /var/lib/puppet/'
      if use_pe
        puppet_tags = "pe"
      else
        puppet_tags = "os"
      end
      # the puppet manifest uses this tag to determine whether to deploy PE or OS using razor
      core_system("vagrant ssh master -c 'sudo puppet agent --test --waitforcert 1 --tags #{puppet_tags}'")
    end
  end

  desc 'fetch the base operating system image'
  task :fetch_image do
    Dir.chdir("razor-puppet-puppetdb-demo/env/#{vagrant_env}") do
      unless File.exists? 'ubuntu-12.04-server-amd64.iso'
        if File.exists? '../../../files/ubuntu-12.04-server-amd64.iso':
            FileUtils.cp '../../../files/ubuntu-12.04-server-amd64.iso', './'
        else
          system('curl -L http://releases.ubuntu.com/precise/ubuntu-12.04-server-amd64.iso -o ubuntu-12.04-server-amd64.iso')
        end
      end
    end
  end

  task :fetch_pe do
    Dir.chdir('files') do
      unless File.exists? 'puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz'
        system('curl -L https://pm.puppetlabs.com/puppet-enterprise/2.5.3/puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz -o puppet-enterprise-2.5.3-ubuntu-12.04-amd64.tar.gz')
      end
    end
  end

  desc 'blow the whole darn thing away'
  task 'destroy' do
    system('vagrant destroy -f')
    Dir.chdir("razor-puppet-puppetdb-demo/env/#{vagrant_env}") do
      system('vagrant destroy -f')
    end
  end

  desc 'deploys the entire environment'
  task :deploy_razor do
    Rake::Task['openstack_demo:install_master'.to_sym].invoke
    Rake::Task['openstack_demo:fetch_image'.to_sym].invoke
    Rake::Task['openstack_demo:setup'.to_sym].invoke
    Rake::Task['openstack_demo:start_master'.to_sym].invoke
    Rake::Task['openstack_demo:configure_razor'.to_sym].invoke
    system("vagrant up")
  end

  'deploys the openstack environment with base boxes (not with razor)'
  task :deploy do
    Rake::Task['openstack_demo:install_master'.to_sym].invoke
    Rake::Task['openstack_demo:setup'.to_sym].invoke
    Rake::Task['openstack_demo:start_master'.to_sym].invoke
    Rake::Task['openstack_demo:configure_razor'.to_sym].invoke
    system("vagrant up")
  end
end
