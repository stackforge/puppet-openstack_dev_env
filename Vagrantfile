def parse_vagrant_config(
  config_file=File.expand_path(File.join(File.dirname(__FILE__), 'config.yaml'))
)
  require 'yaml'
  config = {
    'gui_mode'        => "false",
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

Vagrant::Config.run do |config|

  v_config = parse_vagrant_config

  if v_config['operatingsystem'] and v_config['operatingsystem'] != ''
    if v_config['operatingsystem'].downcase == 'redhat'
      os_name = 'centos'
      config.vm.box     = 'centos'
      config.vm.box_url = 'https://dl.dropbox.com/u/7225008/Vagrant/CentOS-6.3-x86_64-minimal.box'
    elsif v_config['operatingsystem'].downcase == 'ubuntu'
      os_name = 'precise64'
      config.vm.box     = 'precise64'
      config.vm.box_url = 'http://files.vagrantup.com/precise64.box'
    else
      raise(Exception, "undefined operatingsystem: #{v_config['operatingsystem']}")
    end
  end

  ssh_forward_port = 2244

  [
   {'devstack' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.2',
     }
   },
   {'openstack_controller' =>
     {'memory' => 2000,
      'ip1'    => '172.16.0.3'
     }
   },
   {'compute1' =>
     {
       'memory' => 2512,
       'ip1'    => '172.16.0.4'
     }
   },
   {'compute2' =>
     {
       'memory' => 2512,
       'ip1'    => '172.16.0.14'
     }
   },
   {'nova_controller' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.5'
     }
   },
   {'glance' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.6'
     }
   },
   {'keystone' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.7'
     }
   },
   {'mysql' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.8'
     }
   },
   {'cinder' =>
     {
       'memory' => 512,
       'ip1'    => '172.16.0.9'
     }
   },
   { 'quantum_agent' => {
       'memory' => 512,
       'ip1'    => '172.16.0.10'
     }
   },
   { 'swift_proxy' => {
       'memory'   => 512,
       'ip1'      => '172.16.0.21',
       'run_mode' => :agent
     }
   },
   { 'swift_storage_1' => {
       'memory' => 512,
       'ip1'    => '172.16.0.22',
       'run_mode' => :agent
     }
   },
   { 'swift_storage_2' => {
       'memory' => 512,
       'ip1'    => '172.16.0.23',
       'run_mode' => :agent
     }
   },
   { 'swift_storage_3' => {
       'memory' => 512,
       'ip1'    => '172.16.0.24',
       'run_mode' => :agent
     }
   },
   # keystone instance to build out for testing swift
   {
     'swift_keystone' => {
       'memory'   => 512,
       'ip1'      => '172.16.0.25',
       'run_mode' => :agent
     }
   },
   { 'puppetmaster'    => {
       'memory'  => 512,
       'ip1'     => '172.16.0.31'
     }
   },
   { 'openstack_all' => { 'memory' => 2512, 'ip1' => '172.16.0.11'} }
  ].each do |hash|


    name  = hash.keys.first
    props = hash.values.first

    raise "Malformed vhost hash" if hash.size > 1

    config.vm.define name.intern do |agent|
      number = props['ip1'].gsub(/\d+\.\d+\.\d+\.(\d+)/, '\1').to_i
      agent.vm.forward_port(22, ssh_forward_port + number)
      # host only network
      agent.vm.network :hostonly, props['ip1'], :adapter => 2
      agent.vm.network :hostonly, props['ip1'].gsub(/(\d+\.\d+)\.\d+\.(\d+)/) {|x| "#{$1}.1.#{$2}" }, :adapter => 3
      agent.vm.network :hostonly, props['ip1'].gsub(/(\d+\.\d+)\.\d+\.(\d+)/) {|x| "#{$1}.2.#{$2}" }, :adapter => 4
      #agent.vm.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
      # natted network
      #agent.vm.customize ["modifyvm", :id, "--nic3", "hostonly"]
      #agent.vm.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

      #agent.vm.customize ["modifyvm", :id, "--macaddress2", 'auto']
      #agent.vm.customize ["modifyvm", :id, "--macaddress3", 'auto']

      agent.vm.customize ["modifyvm", :id, "--memory", props['memory'] || 2048 ]
      agent.vm.boot_mode = 'gui' if v_config['gui_mode'] == 'true'
      agent.vm.customize ["modifyvm", :id, "--name", "#{name}.puppetlabs.lan"]
      agent.vm.host_name = "#{name.gsub('_', '-')}.puppetlabs.lan"

      if name == 'puppetmaster' || name =~ /^swift/
        node_name = "#{name.gsub('_', '-')}.puppetlabs.lan"
      else
        node_name = "#{name.gsub('_', '-')}-#{Time.now.strftime('%Y%m%d%m%s')}"
      end

      if os_name =~ /precise/
        agent.vm.provision :shell, :inline => "apt-get update"
      elsif os_name =~ /centos/
        agent.vm.provision :shell, :inline => "yum clean all"
      end

      puppet_options = ["--certname=#{node_name}"]
      puppet_options.merge!({'--verbose', '--show_diff'}) if v_config['verbose']

      if v_config['update_repos'] == true

        agent.vm.provision(:puppet, :pp_path => "/etc/puppet") do |puppet|
          puppet.manifests_path = 'manifests'
          puppet.manifest_file  = "setup/#{os_name}.pp"
          puppet.module_path    = 'modules'
          puppet.options        = puppet_options
        end

      else

        agent.vm.provision(:puppet, :pp_path => "/etc/puppet") do |puppet|
          puppet.manifests_path = 'manifests'
          puppet.manifest_file  = "setup/hosts.pp"
          puppet.module_path    = 'modules'
          puppet.options        = puppet_options
        end

      end
      agent.vm.provision :puppet do |puppet|
        puppet.manifests_path = 'manifests'
        puppet.manifest_file  = 'site.pp'
        puppet.module_path    = 'modules'
        #puppet.options = ['--verbose', '--show_diff', "--certname=#{node_name}"]
        puppet.options = ["--certname=#{node_name}"]

      # export a data directory that can be used by hiera
      agent.vm.share_folder("hiera_data", '/etc/puppet/hiera_data', './hiera_data/')

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
