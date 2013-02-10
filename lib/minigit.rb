require 'mixlib/shellout'

require "minigit/version"

class MiniGit
  class GitError < RuntimeError
    attr_reader :command, :status, :info
    def initialize(command, status, info={})
      @status = status.dup
      @command = command
      @info = info
      super("Failed to run git #{command.join(' ')}: #{@status}")
    end
  end

  class << self ; attr_accessor :git_command ; end
  attr_writer :git_command
  def git_command
    @git_command || self.class.git_command || MiniGit.git_command || 'git'
  end

  def git(*args)
    argv = switches_for(*args)
    system git_command, *argv
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
    @capturing ||= Capturing.new
  end

  def noncapturing
    self
  end

  def self.method_missing(meth, *args, &block)
    ( @myself ||= self.new ).git(meth, *args)
  end

  class Capturing < MiniGit
    attr_reader :shellout

    def git(*args)
      argv = switches_for(*args)
      @shellout = Mixlib::ShellOut.new(git_command, *argv)
      @shellout.run_command.error!
      @shellout.stdout
    rescue Mixlib::ShellOut::ShellCommandFailed
      raise GitError.new(argv, @shellout.status, :shellout => @shellout)
    end

    def capturing
      self
    end

    def noncapturing
      @noncapturing ||= MiniGit.new
    end
  end
end
