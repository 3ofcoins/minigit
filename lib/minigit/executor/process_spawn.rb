class MiniGit
  class Executor
    class ProcessSpawn < Executor
      def chatty(*command)
        pid, status = Process.waitpid2(Process.spawn(*command))
        raise ExecuteError, status unless status.success?
      end

      def capture(*command)
        # FIXME: actually read
        r, w = IO.pipe
        out = ''
        pid = Process.spawn(*command, :out => w)
        w.close
        pid, status = Process.waitpid2(pid)
        raise ExecuteError, status unless status.success?
        r.read
      end
    end
  end
end
