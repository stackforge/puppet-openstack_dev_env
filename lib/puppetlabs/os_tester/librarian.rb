require 'puppetlabs/os_tester/system'

module Puppetlabs
  module OsTester

    module Librarian

      include Puppetlabs::OsTester::System

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
    end
  end
end
