module Puppetlabs
  module OsTester
    module System

      # Run a system command
      # Parameters:
      #   cmd::
      #     the command that needs to be executed.
      #   print::
      #     if the returned output should be printed to stdout.
      # Return:
      #   An array of the lines of stdout.
      def cmd_system (cmd, print=true)
        puts "Running cmd: #{Array(cmd).join(' ')}" if print
        output = `#{cmd}`.split("\n")
        puts output.join("\n") if print
        raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
        #Open3.popen3(*cmd) do |i, o, e, t|
        #  output = o.read.split("\n")
        #  raise StandardError, e.read unless (t ? t.value : $?).success?
        #end
        output
      end
    end
  end
end
