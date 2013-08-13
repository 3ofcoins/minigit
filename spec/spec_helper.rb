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

require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/setup'
require 'wrong'

class MiniGit
  module Spec
    module WrongHelper
      include Wrong::Assert
      include Wrong::Helpers

      def increment_assertion_count
        self.assertions += 1
      end
    end

    class Executor
      def call(*args)
        raise RuntimeError, "Unprotected run: #{args.inspect}"
      end
    end

    EXECUTOR = Executor.new
  end
end

require 'minigit'

# MiniTest pokes into these methods, and triggers errors from
# method_missing. Let's give it something to live with.
class MiniGit
  def self.to_str ; to_s ; end
  def self.to_ary ; to_a ; end
  @executor = Spec::EXECUTOR
end

class MiniTest::Spec
  include MiniGit::Spec::WrongHelper

  attr_reader :tmp_path
  before do
    @tmp_path = Pathname.new(__FILE__).dirname.dirname.join('tmp').expand_path
  end
end
