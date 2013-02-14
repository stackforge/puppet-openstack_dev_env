require 'puppetlabs/os_tester/system'

module Puppetlabs
  module OsTester

    module Git

      include Puppetlabs::OsTester::System

      def git_cmd(cmd, print=true)
        cmd_system('git ' + cmd, print)
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
          status = git_cmd('status', false)
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

    end

  end
end
