require 'posix/spawn'

class MiniGit
  class Executor
    class PosixSpawn < Executor
      def chatty(*command)
        pid, status = Process.waitpid2(POSIX::Spawn.spawn(*command))
        raise ExecuteError, status unless status.success?
      end

      def capture(*command)
        child = POSIX::Spawn::Child.new(*command)
        $stderr.write(child.err) unless child.err.empty?
        raise ExecuteError, child.status unless child.status.success?
        child.out
      end
    end
  end
end
