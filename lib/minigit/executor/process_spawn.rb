class MiniGit
  class Executor
    class ProcessSpawn < Executor
      def chatty(*command)
        pid, status = Process.waitpid2(Process.spawn(*command))
        raise ExecuteError, status unless status.success?
      end

      def capture(*command)
        out_r, out_w = IO.pipe
        out = Thread.new { out_r.read }
        status = Process.detach(Process.spawn(*command, :out => out_w))
        out_w.close
        status = status.value
        raise ExecuteError, status unless status.success?
        out.value
      end
    end
  end
end
