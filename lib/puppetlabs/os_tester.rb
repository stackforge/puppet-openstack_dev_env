#
# class that hold utilities that I use to test openstack
#
module Puppetlabs
  module OsTester

    require 'yaml'
    require 'github_api'
    require 'open3'

    class TestException < Exception
    end

    def cmd_system (cmd, print=true)
      puts "Running cmd: #{Array(cmd).join(' ')}" if print
      output = `#{cmd}`.split("\n")
      puts output.join("\n") if print
      raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
      #Open3.popen3(*cmd) do |i, o, e, t|
      #  output = o.read.split("\n")
      #  raise StandardError, e.read unless (t ? t.value : $?).success?
      #end
      output
    end

    def git_cmd(cmd, print=true)
      cmd_system('git ' + cmd, print)
    end

    def vagrant_command(cmd, box='')
      require 'vagrant'
      env = Vagrant::Environment.new(:ui_class => Vagrant::UI::Colored)
      env.cli(cmd, box)
    end

    def on_box (box, cmd)
      require 'vagrant'
      env = Vagrant::Environment.new(:ui_class => Vagrant::UI::Colored)
      raise("Invalid VM: #{box}") unless vm = env.vms[box.to_sym]
      raise("VM: #{box} was not already created") unless vm.created?
      ssh_data = ''
      #vm.channel.sudo(cmd) do |type, data|
      vm.channel.sudo(cmd) do |type, data|
        ssh_data = data
        env.ui.info(ssh_data.chomp, :prefix => false)
      end
      ssh_data
    end

    def swift_nodes
      [
       'swift_storage_1',
       'swift_storage_2',
       'swift_storage_3',
       'swift_proxy',
       'swift_keystone'
      ]
    end

    # destroy all vagrant instances
    def destroy_all_vms
      puts "About to destroy all vms..."
      vagrant_command('destroy -f')
      puts "Destroyed all vms"
    end

    def destroy_swift_vms
      puts "About to destroy all swift vms..."
      swift_nodes.each do |x|
        cmd_system("vagrant destroy #{x} --force")
      end
      puts "Destroyed all swift vms"
      on_box('puppetmaster', 'export RUBYLIB=/etc/puppet/modules-0/ruby-puppetdb/lib/; puppet query node --only-active --deactivate --puppetdb_host=puppetmaster.puppetlabs.lan --puppetdb_port=8081 --config=/etc/puppet/puppet.conf --ssldir=/var/lib/puppet/ssl --certname=puppetmaster.puppetlabs.lan')
      on_box('puppetmaster', 'rm /var/lib/puppet/ssl/*/swift*;rm /var/lib/puppet/ssl/ca/signed/swift*;')
    end

    # adds the specified remote name as a read/write remote
    def dev_setup(remote_name)
      each_repo do |module_name|
        # need to handle more failure cases
        remotes = git_cmd('remote')
        if remotes.include?(remote_name)
          puts "Did not have to add remote #{remote_name} to #{module_name}"
        elsif ! remotes.include?('origin')
          raise(TestException, "Repo #{module_name} has no remote called origin, failing")
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


    def pull_all
      each_repo do |module_name|
        puts "Pulling repo: #{module_name}"
        puts '  ' + git_cmd('pull').join("\n  ")
      end
    end


    def status_all
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

    def check_tags(project_name=nil)
      each_repo do |module_name|
        require 'puppet'
        if ! project_name || project_name == module_name
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
    end

    # given a pull request, return true if we should test it.
    # this means that is can be merged, and has a comment where one of the admin users

    def deploy_two_node
      ['openstack_controller', 'compute1'].each do |vm|
        vagrant_command('up', vm)
      end
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

    def refresh_modules
      ['modules', '.librarian', 'Puppetfile.lock', '.tmp', checkedoutfile_name].each do |dir|
        if File.exists?(File.join(base_dir, dir ))
          FileUtils.rm_rf(File.join(base_dir, dir))
        end
      end
      FileUtils.rm(checkedout_file) if File.exists?(checkedout_file)
      cmd_system('librarian-puppet install')
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


    # has specified the expected body.
    def testable_pull_request?(
      pr,
      admin_users,
      expected_body = 'test_it',
      options       = {}
    )
      if ! pr['merged']
        if pr['mergeable']
          if pr['comments'] > 0
            comments = Github.new(options).issues.comments.all(
              pr['base']['user']['login'],
              pr['base']['repo']['name'],
              pr['number']
            )
            puts 'going through comments'
            comments.each do |comment|
              if admin_users.include?(comment['user']['login'])
                if comment['body'] == expected_body
                  return true
                end
              end
            end
          else
            puts "PR: #{pr['number']} from #{pr['base']['repo']['name']} has no issue commments.\
            I will not test it. We only test things approved.
            "
          end
        else
          puts "PR: #{pr['number']} from #{pr['base']['repo']['name']} cannot be merged, will not test"
        end
      else
        puts "PR: #{pr['number']} from #{pr['base']['repo']['name']} was already merged, will not test"
      end
      puts "Did not find comment matching #{expected_body}"
      return false
    end

    def checkedoutfile_name
      '.current_testing'
    end

    def checkedout_file
      File.join(base_dir, checkedoutfile_name)
    end

    def checkedout_branch
      return @checkout_branch_results if @checkout_branch_results_results
      co_file = checkedout_file
      if File.exists?(co_file)
        @checkout_branch_results = YAML.load_file(co_file)
      else
        @checkout_branch_results = {}
      end
    end

    def write_checkedout_file(project_name, number)
      File.open(checkedout_file, 'w') do |fh|
        fh.write({
          :project => project_name,
          :number  => number
        }.to_yaml)
      end
    end

    def checkout_pr(project_name, number, admin_users, expected_body, options)
      # but I should write some kind of repo select
      # depends on https://github.com/peter-murach/github
      require 'github_api'

      each_repo do |repo_name|
        if repo_name == project_name
          pr = Github.new(options).pull_requests.get('puppetlabs', "puppetlabs-#{project_name}", number)
          # need to be able to override this?
          if checkedout_branch[:project]
            if checkedout_branch[:project] == project_name and checkedout_branch[:number] == number
              puts "#{project_name}/#{number} already checkout out, not doing it again"
              return
            else
              raise(TestException, "Wanted to checkout: #{project_name}/#{number}, but #{checkedout_branch[:project]}/#{checkedout_branch[:number]} was already checked out")
            end
          end

          if testable_pull_request?(pr, admin_users, expected_body, options)
            clone_url   = pr['head']['repo']['clone_url']
            remote_name = pr['head']['user']['login']
            sha         = pr['head']['sha']

            base_ref    = pr['base']['ref']
            if base_ref != 'master'
              raise(TestException, "At the moment, I do not support non-master base refs")
            end

            unless (diffs = git_cmd("diff origin/master")) == []
              raise(TestException, "There are differences between the current checked out branch and master, you need to clean up these branhces before running any tests\n#{diffs.join("\n")}")
            end

            write_checkedout_file(project_name, number)
            puts 'found one that we should test'
            # TODO I am not sure how reliable all of this is going
            # to be
            remotes = git_cmd('remote')
            unless remotes.include?(remote_name)
              git_cmd("remote add #{remote_name} #{clone_url}")
            end
            git_cmd("fetch #{remote_name}")
            # TODO does that work if master has been updated?
            git_cmd("merge #{sha}")
          else
            raise("pull request #{project_name}/#{number} is not testable")
          end
        end
      end
    end

    # publish a string as a gist.
    # publish a link to that gist as a issue comment.
    def publish_results(project_name, number, outcome, body, options)
      require 'github_api'
      github = Github.new(options)
      gist_response = github.gists.create(
        'description' => "#{project_name}/#{number}@#{Time.now.strftime("%Y%m%dT%H%M%S%z")}",
        'public'      => true,
        'files' => {
          'file1' => {'content' => body}
        }
      )
      comments = github.issues.comments.create(
        'puppetlabs',
        "puppetlabs-#{project_name}",
        number,
        'body' => "Test #{outcome}. Results can be found here: #{gist_response.html_url}"
      )
    end


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

    def update_vagrant_os(os)
      cfg = File.join(base_dir, 'config.yaml')
      yml = YAML.load_file(cfg).merge({'operatingsystem' => os})
      File.open(cfg, 'w') {|f| f.write(yml.to_yaml) }
    end

    # iterate through each testable pull request
    def each_testable_pull_request(&block)
    end

  end
end
