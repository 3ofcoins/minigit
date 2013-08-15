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
  end
end
