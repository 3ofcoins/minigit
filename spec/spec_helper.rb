require 'rubygems'
require 'bundler/setup'
Bundler.setup

require 'fileutils'
require 'pathname'

require 'simplecov'
SimpleCov.start do
  command_name 'MiniTest::Spec'
  minimum_coverage 95
end

require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/setup'
require 'wrong'
require 'wrong/adapters/minitest'

begin
  require 'minitest/ansi'
rescue LoadError                # that's fine, we'll live without it
else
  MiniTest::ANSI.use! if STDOUT.tty?
end

require 'minigit'

# MiniTest pokes into these methods, and triggers errors from
# method_missing. Let's give it something to live with.
class MiniGit
  def self.to_str ; to_s ; end
  def self.to_ary ; to_a ; end
end

class MiniTest::Spec
  attr_reader :tmp_path
  before do
    @tmp_path = Pathname.new(__FILE__).dirname.dirname.join('tmp').expand_path
  end
end
