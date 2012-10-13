Vagrant::Config.run do |config|

  config.vm.box     = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  if ENV['OPENSTACK_GUI_MODE']
    gui_mode = ENV['OPENSTACK_GUI_MODE'].to_bool
  else
    gui_mode = true
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
   #{'compute_1'  =>
   #  {'ip1' => '172.16.0.4'}
   #},
   #{'compute_2'  =>
   #  {'ip1' => '172.16.0.5'}
   }
  ].each do |hash|


    name  = hash.keys.first
    props = hash.values.first

    raise "Malformed vhost hash" if hash.size > 1

    config.vm.define name.intern do |agent|
      ssh_forward_port = ssh_forward_port + 1
      agent.vm.forward_port(22, ssh_forward_port)
      # host only network
      agent.vm.network :hostonly, props['ip1'], :adapter => 2
      agent.vm.network :hostonly, props['ip1'].gsub(/(\d+\.\d+)\.\d+\.(\d+)/) {|x| "#{$1}.1.#{$2}" }, :adapter => 3
      #agent.vm.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
      # natted network
      #agent.vm.customize ["modifyvm", :id, "--nic3", "hostonly"]
      #agent.vm.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]

      #agent.vm.customize ["modifyvm", :id, "--macaddress2", 'auto']
      #agent.vm.customize ["modifyvm", :id, "--macaddress3", 'auto']

      agent.vm.customize ["modifyvm", :id, "--memory", props['memory'] || 2048 ]
      agent.vm.boot_mode = 'gui' if gui_mode
      agent.vm.customize ["modifyvm", :id, "--name", "#{name}.puppetlabs.lan"]
      agent.vm.host_name = "#{name.gsub('_', '-')}.puppetlabs.lan"

      node_name = "#{name.gsub('_', '-')}-#{Time.now.strftime('%Y%m%d%m%s')}"

      agent.vm.provision :shell, :inline => "apt-get update"
      #agent.vm.provision :shell, :inline => "apt-get -y upgrade"

      agent.vm.provision :puppet do |puppet|
        puppet.manifests_path = 'manifests'
        puppet.manifest_file  = 'hosts.pp'
        puppet.module_path    = 'modules'
        puppet.options = ['--verbose', '--debug', '--show_diff',  "--certname=#{node_name}"]
      end
      agent.vm.provision :puppet do |puppet|
        puppet.manifests_path = 'manifests'
        puppet.manifest_file  = 'site.pp'
        puppet.module_path    = 'modules'
        puppet.options = ['--verbose', '--debug', '--show_diff', "--certname=#{node_name}"]
      end
    end
  end
end
