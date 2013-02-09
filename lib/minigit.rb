require "minigit/version"

class MiniGit
  class GitError < RuntimeError
    attr_reader :command, :status
    def initialize(command, status)
      @status = status.dup
      @command = command
      super("Failed to run git #{command.join(' ')}: #{@status}")
    end
  end

  def git(*args)
    argv = switches_for(*args)
    system 'git', *argv
    raise GitError.new(argv, $?) unless $?.success?
  end

  def method_missing(meth, *args)
    self.git(meth, *args)
  end

  def switches_for(*args)
    rv = []
    args.each do |arg|
      case arg
      when Hash
        arg.keys.sort_by(&:to_s).each do |k|
          short = (k.to_s.length == 1)
          switch = short ? "-#{k}" : "--#{k}".gsub('_', '-')
          Array(arg[k]).each do |value|
            if value == true
              rv << switch
            elsif short
              rv << switch
              rv << value.to_s
            else
              rv << "#{switch}=#{value}"
            end
          end
        end
      when String
        rv << arg
      when Enumerable
        rv += switches_for(*arg)
      when Symbol
        rv << arg.to_s.gsub('_', '-')
      else
        rv << arg.to_s
      end
    end
    rv
  end
end
