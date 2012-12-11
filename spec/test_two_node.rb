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

  describe 'test redhat' do

    before :each do
      update_vagrant_os('redhat')
    end

    it 'should be able to build out a two node environment' do
      deploy_two_node
      result = on_box('openstack_controller', 'sudo bash /tmp/test_nova.sh;exit $?')
      result.split("\n").last.should == 'cirros'
    end

  end

  describe 'test ubuntu' do
    before :each do
      update_vagrant_os('ubuntu')
    end

    it 'should be able to build out a two node environment' do
      deploy_two_node
      result = on_box('openstack_controller', 'sudo bash /tmp/test_nova.sh;exit $?')
      result.split("\n").last.should == 'cirros'
    end
  end

  after :all do

  end

end
