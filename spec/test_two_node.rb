require File.join(
  File.dirname(__FILE__),
  '..',
  'lib',
  'puppetlabs',
  'os_tester'
)

describe 'test various two node configurations' do

  def base_dir
    File.join(File.dirname(__FILE__), '..')
  end

  include Puppetlabs::OsTester

  before :each do
    cmd_system('vagrant destroy -f')
  end

  [
    'redhat',
    'ubuntu'
  ].each do |os|

    describe "test #{os}" do

      it 'should be able to build out a two node environment' do
        update_vagrant_os(os)
        deploy_two_node
        # on box runs as sudo
        result = on_box('openstack_controller', 'bash /tmp/test_nova.sh;exit $?')
        result.split("\n").last.should == 'cirros'
      end

    end
  end

  after :all do

  end

end
