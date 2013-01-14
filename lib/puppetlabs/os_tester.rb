#
# class that hold utilities that I use to test openstack
#
module Puppetlabs
  module OsTester

    require 'yaml'
    require 'github_api'
    require 'open3'
    # need to fix this lib stuff. its is lame :(
    require 'puppetlabs/os_tester/system'
    require 'puppetlabs/os_tester/git'
    require 'puppetlabs/os_tester/github'
    require 'puppetlabs/os_tester/librarian'
    require 'puppetlabs/os_tester/openstack'
    require 'puppetlabs/os_tester/swift'

    class TestException < Exception
    end


    include System
    include Git
    include Swift
    include Openstack
    include Github
    include Librarian
  end
end
