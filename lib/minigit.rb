require 'pathname'
require 'mixlib/shellout'

require "minigit/version"

class MiniGit
  class << self
    attr_accessor :git_command

    def method_missing(meth, *args, &block)
      ( @myself ||= self.new ).git(meth, *args)
    end
  end

  class GitError < RuntimeError
    attr_reader :command, :status, :info
    def initialize(command, status, info={})
      @status = status.dup
      @command = command
      @info = info
      super("Failed to run git #{command.join(' ')}: #{@status}")
    end
  end

  attr_writer :git_command
  attr_reader :git_dir, :git_work_tree

  def git_command
    @git_command || self.class.git_command || MiniGit.git_command || 'git'
  end

  def find_git_dir(where)
    path = Pathname.new(where)
    raise ArgumentError, "#{where} does not seem to exist" unless path.exist?
    path = path.dirname unless path.directory?
    grp = Mixlib::ShellOut.new(
      git_command, 'rev-parse', '--git-dir', '--show-toplevel',
      :cwd => path.to_s)
    grp.run_command
    grp.error!
    grp.stdout.lines.map { |ln| path.join(Pathname.new(ln.strip)).realpath.to_s }
  rescue Mixlib::ShellOut::ShellCommandFailed
    raise ArgumentError, "Invalid repository path #{where}; Git said: #{grp.stderr.inspect}"
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
    system(
      {'GIT_DIR' => git_dir, 'GIT_WORK_TREE' => git_work_tree},
      git_command, *argv)
    raise GitError.new(argv, $?) unless $?.success?
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
    attr_reader :shellout

    def git(*args)
      argv = switches_for(*args)
      @shellout = Mixlib::ShellOut.new(git_command, *argv,
        :environment => { 'GIT_DIR' => git_dir, 'GIT_WORK_TREE' => git_work_tree })
      @shellout.run_command.error!
      @shellout.stdout
    rescue Mixlib::ShellOut::ShellCommandFailed
      raise GitError.new(argv, @shellout.status, :shellout => @shellout)
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
end
