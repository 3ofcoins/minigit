require 'shellwords'

class MiniGit
  class Executor
    class KernelExecutor < Executor
      def chatty(*command)
        handling_status do
          ::Kernel.system(*command)
        end
      end

      def capture(*command)
        handling_status do
          `#{Shellwords.join(command)}`
        end
      end

      private

      def handling_status
        yield
      ensure
        raise ExecuteError, ($?.dup rescue $?.to_s) unless $?.success?
      end
    end
  end
end
