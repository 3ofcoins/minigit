require 'minigit/executor/kernel'
require 'minigit/executor/process_spawn' if Process.respond_to?(:spawn)

begin
  require 'posix/spawn'
rescue LoadError
  # pass
else
  require 'minigit/executor/posix_spawn'
end

class MiniGit
  class Executor
    class ExecuteError < RuntimeError ; end

    def initialize(options={})
      @options = options
    end

    def run(*command)
      if @options[:capturing]
        capture(*command)
      else
        chatty(*command)
      end
    end

    def chatty(*command)
      raise NotImplementedError
    end

    def capture(*command)
      raise NotImplementedError
    end

    DefaultExecutor =
      defined?(PosixSpawn)   ? PosixSpawn :
      defined?(ProcessSpawn) ? ProcessSpawn :
      System
  end
end
