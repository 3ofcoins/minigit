require 'pathname'
require 'shellwords'

require "minigit/version"

class MiniGit
  class << self
    attr_accessor :debug
    attr_writer :git_command

    def git_command
      @git_command || ( (self==::MiniGit) ? 'git' : ::MiniGit.git_command )
    end

    def method_missing(meth, *args, &block)
      _myself.git(meth, *args)
    end

    def git(*args)
      _myself.git(*args)
    end

    def [](arg)
      _myself[arg]
      end

    def []=(key, value)
      _myself[key] = value
    end

    protected

    def _myself
      @myself ||= self.new
    end
  end

  class GitError < RuntimeError
    attr_reader :command, :status, :info
    def initialize(command=[], status=nil, info={})
      @status = status.dup rescue status.to_s
      @command = command
      @info = info
      super("Failed to run git #{command.join(' ')}: #{@status}")
    end
  end

  attr_writer :git_command
  attr_reader :git_dir, :git_work_tree

  def git_command
    @git_command || self.class.git_command
  end

  def find_git_dir(where)
    path = Pathname.new(where)
    raise ArgumentError, "#{where} does not seem to exist" unless path.exist?
    path = path.dirname unless path.directory?
    Dir.chdir(path.to_s) do
      out = `#{git_command} rev-parse --git-dir --show-toplevel`
      $stderr.puts "+ [#{Dir.pwd}] #{git_command} rev-parse --git-dir --show-toplevel # => #{out.inspect}" if MiniGit.debug
      raise ArgumentError, "Invalid repository path #{where}" unless $?.success?
      out
    end.lines.map { |ln| path.join(Pathname.new(ln.strip)).realpath.to_s }
  end

  def initialize(where=nil, opts={})
    where, opts = nil, where if where.is_a?(Hash)
    @git_command = opts[:git_command] if opts[:git_command]
    if where
      @git_dir, @git_work_tree = find_git_dir(where)
    else
      @git_dir = opts[:git_dir] if opts[:git_dir]
      @git_work_tree = opts[:git_work_tree] if opts[:git_work_tree]
    end
  end

  def git(*args)
    argv = switches_for(*args)
    with_git_env do
      $stderr.puts "+ #{git_command} #{Shellwords.join(argv)}" if MiniGit.debug
      rv = system(git_command, *argv)
      raise GitError.new(argv, $?) unless $?.success?
      rv
    end
  end

  def method_missing(meth, *args, &block)
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

  def capturing
    @capturing ||= Capturing.new(:git_command => @git_command,
      :git_dir => @git_dir,
      :git_work_tree => @git_work_tree)
  end

  def noncapturing
    self
  end

  class Capturing < MiniGit
    attr_reader :process

    def system(*args)
      `#{Shellwords.join(args)}`
    end

    def capturing
      self
    end

    def noncapturing
      @noncapturing ||= MiniGit.new(:git_command => @git_command,
        :git_dir => @git_dir,
        :git_work_tree => @git_work_tree)
    end
  end

    def [](arg)
      begin
      self.capturing.config(arg).strip
      rescue MiniGit::GitError
        nil
      end
    end

    def []=(key, value)
      begin
        self.noncapturing.config(key, value)
      rescue MiniGit::GitError
        nil
      end
    end

  private

  def with_git_env
    dir, work_tree = ENV['GIT_DIR'], ENV['GIT_WORK_TREE']
    ENV['GIT_DIR'] = git_dir
    ENV['GIT_WORK_TREE'] = git_work_tree
    yield
  ensure
    if dir then ENV['GIT_DIR'] = dir else ENV.delete('GIT_DIR') end
    if work_tree then ENV['GIT_WORK_TREE'] = work_tree else ENV.delete('GIT_WORK_TREE') end
  end

end
