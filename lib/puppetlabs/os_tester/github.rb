
require 'puppetlabs/os_tester/librarian'

module Puppetlabs
  module OsTester

    module Github

      include Puppetlabs::OsTester::Librarian

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
    end # end Github

  end
end
