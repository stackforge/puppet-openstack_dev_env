require 'puppetlabs/os_tester'

describe 'build out a swift cluster and test it' do

  def base_dir
    File.join(File.dirname(__FILE__), '..')
  end

  include Puppetlabs::OsTester

  before :all do
    cmd_system('vagrant destroy -f')
  end

  before :each do
    destroy_swift_vms
    deploy_puppetmaster
  end

  ['ubuntu'].each do |os|
    describe "testing #{os}" do
      before :each do
        update_vagrant_os(os)
      end

      it 'should be able to build out a full swift cluster' do
        deploy_swift_cluster
        result = test_swift
        puts result.inspect
        result.split("\n").last.should =~ /Dude/
      end
    end
  end

end
