require 'shellwords'

class MiniGit
  module Executors
    class ExecuteError < RuntimeError ; end

    KERNEL_SYSTEM = Proc.new do |*command|
      begin
        options = command.last.is_a?(Hash) ? command.pop : {}
        if options[:capture_stdout]
          rv = `#{Shellwords.join(command)}`
        else
          rv = ::Kernel.system(*command)
        end
      ensure
        raise ExecuteError, ($?.dup rescue $?.to_s) unless $?.success?
      end
    end

    def self.capturing(parent)
      Proc.new do |*command|
        options = command.last.is_a?(Hash) ? command.pop : {}
        options[:capture_stdout] ||= true
        command << options
        parent.call(*command)
      end
    end
  end
end
