require 'yaml'
require 'rubygems'

def base_dir
  File.expand_path(File.dirname(__FILE__))
end

require File.join(base_dir, 'lib', 'puppetlabs', 'os_tester')

include Puppetlabs::OsTester

def github_password
  YAML.load_file(File.join(base_dir, '.github_auth'))['password']
end

def github_login
  YAML.load_file(File.join(base_dir, '.github_auth'))['login']
end


namespace :openstack do

  desc 'clone all required modules'
  task :setup do
    cmd_system('librarian-puppet install')
  end

  desc 'destroy all vms'
  task 'destroy' do
    destroy_all_vms
  end

  desc 'destroy all swift vms'
  task 'destroy_swift' do
    destroy_swift_vms
  end

  desc 'deploys the entire environment'
  task :deploy_two_node do
    deploy_two_node
  end

  desc 'deploy a swift cluster'
  task :deploy_swift do
    deploy_swift_cluster
  end

end


namespace :git do

  cwd = base_dir

  desc 'for all repos in the module directory, add a read/write remote'
  task :dev_setup do
    dev_setup(github_login)
  end

  desc 'pull the latest version of all code'
  task :pull_all do
    pull_all
  end

  desc 'shows the current state of code that has not been commited'
  task :status_all do
    status_all
  end

  desc 'make sure that the current version from the module file matches the last tagged version'
  task :check_tags , [:project_name] do |t, args|
    # I need to be able to return this as a data structure
    # when I start to do more complicated things like
    # automated releases, I will need this data
    check_tags(args.project_name)
  end

  desc 'make sure that the current version from the module file matches the last tagged version'
  task :check_all_tags do
    check_tags
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


namespace :github do

  desc 'pick a single pull request to test. Accepts the project name and number of PR to test'
    # you can also specify the OPERATINGSYSTEM to test as an ENV variable
  task :checkout_pull_request, [:project_name, :number] do |t, args|
    checkout_pr(
      args.project_name,
      args.number,
      [github_login],
      'test_it',
      {
        :login    => github_login,
        :password => github_password
      }
    )
  end

end

namespace :test do

  desc 'reset test environment'
  task :reset do
    refresh_modules
    destroy_all_vms
  end

  desc 'checkout and test a pull request, publish the results'
  task 'pull_request', [:project_name, :number] do |t, args|
    log_dir = File.join(base_dir, 'logs')
    log_file = File.join(log_dir, "#{Time.now.to_i.to_s}.log")
    FileUtils.mkdir(log_dir) unless File.exists?(log_dir)
    refresh_modules
    checkout_pr(
      args.project_name,
      args.number,
      [github_login],
      'test_it',
      {
        :login    => github_login,
        :password => github_password
      }
    )
    system "bash -c 'rspec spec/test_two_node.rb;echo $?' 2>&1 | tee #{log_file}"
    results = File.read(log_file)
    publish_results(
      args.project_name,
      args.number,
      results.split("\n").last == '0' ? 'passed' : 'failed',
      results,
      {
        :login    => github_login,
        :password => github_password
      }
    )
  end

  desc 'test openstack with basic test script on redhat and ubuntu'
  task 'two_node' do
    test_two_node(['redhat', 'ubuntu'])
  end

  desc 'test all in one deployment on redhat/ubuntu (not yet implemented)'
  task 'all_in_one' do

  end

  desc 'test that openstack can boot an image from the vagrant box'
  task :controller do
    on_box('openstack_controller', 'sudo bash /tmp/test_nova.sh;exit $?')
  end
end
