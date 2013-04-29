# A little helper method for loading an external config.
def parse_vagrant_config(config_file=File.expand_path(File.join(File.dirname(__FILE__), 'config.yaml')))

  require 'yaml'

  # Defaults for when you don't load a config.
  config = {
    'gui_mode'        => false,
    'operatingsystem' => 'ubuntu',
    'verbose'         => false,
    'update_repos'    => true
  }

  if File.exists?(config_file)
    overrides = YAML.load_file(config_file)
    config.merge!(overrides)
  end

  config
end

Vagrant.configure("2") do |config|

  # Use our helper method from above to load our external config.
  v_config = parse_vagrant_config

  # Base config hash for all the nodes we can bring up.  Includes memory and ip
  # plus a few more pieces related to puppet.
  [
   { 'devstack'             => { 'memory' => 512,  'ip1' => '172.16.0.2', } },
   { 'openstack_controller' => { 'memory' => 2000, 'ip1' => '172.16.0.3', } },
   { 'compute1'             => { 'memory' => 2512, 'ip1' => '172.16.0.4', } },

   # compute2 is specifically for running on hardware with a lot of memory, i.e.
   # tempest.
   { 'compute2'        => { 'memory' => 12000, 'ip1' => '172.16.0.14' } },
   { 'nova_controller' => { 'memory' => 512,   'ip1' => '172.16.0.5'  } },
   { 'glance'          => { 'memory' => 512,   'ip1' => '172.16.0.6'  } },
   { 'keystone'        => { 'memory' => 512,   'ip1' => '172.16.0.7'  } },
   { 'mysql'           => { 'memory' => 512,   'ip1' => '172.16.0.8'  } },
   { 'cinder'          => { 'memory' => 512,   'ip1' => '172.16.0.9'  } },
   { 'quantum_agent'   => { 'memory' => 512,   'ip1' => '172.16.0.10' } },
   { 'swift_proxy'     => { 'memory' => 512,   'ip1' => '172.16.0.21', 'run_mode' => :agent } },
   { 'swift_storage_1' => { 'memory' => 512,   'ip1' => '172.16.0.22', 'run_mode' => :agent } },
   { 'swift_storage_2' => { 'memory' => 512,   'ip1' => '172.16.0.23', 'run_mode' => :agent } },
   { 'swift_storage_3' => { 'memory' => 512,   'ip1' => '172.16.0.24', 'run_mode' => :agent } },

   # Keystone instance to build out for testing swift
   { 'swift_keystone' => { 'memory' => 512,  'ip1' => '172.16.0.25', 'run_mode' => :agent } },

   # A puppet master is we are so inclined to use one.
   { 'puppetmaster'   => { 'memory' => 512,  'ip1' => '172.16.0.31', 'operatingsystem' => 'ubuntu' } },

   # A node for puting all of openstack on a single VM.
   { 'openstack_all'  => { 'memory' => 2512, 'ip1' => '172.16.0.11', } }
  ].each do |hash|

    name  = hash.keys.first
    props = hash.values.first
    raise "Malformed vhost hash" if hash.size > 1

    config.vm.define name.intern do |agent|

      # let nodes override their OS
      operatingsystem = (props['operatingsystem'] || v_config['operatingsystem']).downcase

      # Initializing this early.
      os_name = case operatingsystem
                when 'redhat'
                  'centos'
                when 'ubuntu'
                  'precise64'
                end

      # VMware Fusion provider specific configurations.
      agent.vm.provider :vmware_fusion do |v, the_config|
        v.vmx['memsize']     = props['memory'] || 2048
        v.vmx['displayName'] = "#{name}.local.puppetlabs.net"
        the_config.vm.box    = "#{os_name}_vmware_fusion"
        # default to config file, but let hosts override it
        if operatingsystem and operatingsystem != ''
          case operatingsystem
          when 'redhat'
            the_config.vm.box_url = 'https://dl.dropbox.com/u/5721940/vagrant-boxes/vagrant-centos-6.4-x86_64-vmware_fusion.box'
          when 'ubuntu'
            the_config.vm.box_url = 'http://files.vagrantup.com/precise64_vmware_fusion.box'
          else
            raise(Exception, "undefined operatingsystem: #{operatingsystem}")
          end
        end
      end

      # Virtualbox provider specific configurations.
      agent.vm.provider :virtualbox do |v, the_config|
        v.customize ["modifyvm", :id, "--memory", props['memory'] || 2048 ]
        v.customize ["modifyvm", :id, "--name", "#{name}.local.puppetlabs.net"]
        the_config.vm.box     = "#{os_name}_virtualbox"
        # default to config file, but let hosts override it
        if operatingsystem and operatingsystem != ''
          case operatingsystem
          when 'redhat'
            the_config.vm.box_url = 'https://dl.dropbox.com/u/5721940/vagrunt-boxes/vagrant-centos-6.4-x86_64.box'
          when 'ubuntu'
            the_config.vm.box_url = 'http://files.vagrantup.com/precise64.box'
          else
            raise(Exception, "undefined operatingsystem: #{operatingsystem}")
          end
        end
      end

      # Setting up networking.
      number = props['ip1'].gsub(/\d+\.\d+\.\d+\.(\d+)/, '\1').to_i
      agent.ssh.forward_agent = true
      # Multiple private network interfaces.  We use the IPs from the earlier defined hash
      # but replace the 0 from octet with another number.
      agent.vm.network :private_network, ip: props['ip1']
      agent.vm.network :private_network, ip: props['ip1'].gsub(/(\d+\.\d+)\.\d+\.(\d+)/) { |x| "#{$1}.1.#{$2}" }
      agent.vm.network :private_network, ip: props['ip1'].gsub(/(\d+\.\d+)\.\d+\.(\d+)/) { |x| "#{$1}.2.#{$2}" }
      agent.vm.boot_mode = 'gui' if v_config['gui_mode'] == 'true'
      agent.vm.hostname = "#{name.gsub('_', '-')}.local.puppetlabs.net"

      # We using a puppet master or not?
      if name == 'puppetmaster' || name =~ /^swift/
        node_name = "#{name.gsub('_', '-')}.local.puppetlabs.net"
      else
        node_name = "#{name.gsub('_', '-')}-#{Time.now.strftime('%Y%m%d%m%s')}"
      end

      # Shell provisioner to update VM package metadata caches.
      if os_name =~ /precise/
        agent.vm.provision :shell, :inline => "apt-get -o Acquire::http::Proxy=http://172.16.0.1:3128 update"
      elsif os_name =~ /centos/
        agent.vm.provision :shell, :inline => "http_proxy=http://172.16.0.1:3128 yum clean all"
      end

      # Puppet provisioning time...puppet provisioner runs a couple times
      puppet_options = ["--certname=#{node_name}"]
      puppet_options.merge!(['--verbose', '--show_diff']) if v_config['verbose']

      # configure hosts, install hiera
      # perform pre-steps that always need to occur
      agent.vm.provision(:puppet, :pp_path => "/etc/puppet") do |puppet|
        puppet.manifests_path = 'manifests'
        puppet.manifest_file  = "setup/hosts.pp"
        puppet.module_path    = 'modules'
        puppet.options        = puppet_options
      end

      if v_config['update_repos'] == true

        agent.vm.provision(:puppet, :pp_path => "/etc/puppet") do |puppet|
          puppet.manifests_path = 'manifests'
          puppet.manifest_file  = "setup/#{os_name}.pp"
          puppet.module_path    = 'modules'
          puppet.options        = puppet_options
        end

      end

      # export a data directory that can be used by hiera
      agent.vm.synced_folder "hiera_data/", "/etc/puppet/hiera_data"

      run_mode = props['run_mode'] || :apply

      if run_mode == :apply

        agent.vm.provision(:puppet, :pp_path => "/etc/puppet") do |puppet|
          puppet.manifests_path = 'manifests'
          puppet.manifest_file  = 'site.pp'
          puppet.module_path    = 'modules'
          puppet.options        = puppet_options
        end

      elsif run_mode == :agent

        agent.vm.provision(:puppet_server) do |puppet|
          puppet.puppet_server = 'puppetmaster.puppetlabs.lan'
          puppet.options       = puppet_options + ['-t', '--pluginsync']
        end

      else
        puts "Found unexpected run_mode #{run_mode}"
      end
    end
  end
end

# /* vim: set filetype=ruby: */
