require 'spec_helper'

require 'pathname'

describe MiniGit do
  let(:git) { MiniGit::new }

  describe '#switches_for' do
    it 'passes regular arguments' do
      assert { git.switches_for('foo') == %w'foo' }
      assert { git.switches_for('foo', 'bar') == %w'foo bar' }
      assert { git.switches_for('foo', 'bar', 'baz quux') == ['foo', 'bar', 'baz quux'] }
    end

    it 'converts hashes to switches' do
      assert { git.switches_for(:foo => 'bar') == %w'--foo=bar' }
      assert { git.switches_for(:f => 'bar') == %w'-f bar' }
      assert { git.switches_for('foo', 'bar', :baz => 'quux') == %w'foo bar --baz=quux' }
      assert { git.switches_for({ :foo => 'bar' }, 'baz', 'quux') == %w'--foo=bar baz quux' }
    end

    it 'sorts switch names in hash' do
      assert { git.switches_for(:foo => 'bar', :baz => 'quux') == %w'--baz=quux --foo=bar' }
    end

    it 'converts underscores to dashes' do
      assert { git.switches_for(:foo_bar_baz => 'quux') == %w'--foo-bar-baz=quux' }
    end

    it 'recursively flattens the arrays' do
      assert { git.switches_for('foo', ['bar', 'baz'], 'quux') == %w'foo bar baz quux' }
      assert { git.switches_for('foo', ['bar', ['baz']], 'quux') == %w'foo bar baz quux' }
      assert { git.switches_for('foo', ['bar', :baz => 'quux'], 'xyzzy') == %w'foo bar --baz=quux xyzzy' }
    end

    it 'multiplies the switch if hash value is an array' do
      assert { git.switches_for(:foo => ['bar', 'baz', 'quux']) == %w'--foo=bar --foo=baz --foo=quux' }
    end

    it 'converts positional aruments to strings' do
      assert { git.switches_for(:foo, Pathname.new(__FILE__)) == ['foo', __FILE__] }
    end

    it 'interpretes true value as a boolean switch' do
      assert { git.switches_for(:foo => true) == %w'--foo' }
      assert { git.switches_for(:f => true) == %w'-f' }
    end


    it 'converts underscore to dash in a positional symbol' do
      assert { git.switches_for(:foo_bar, 'baz_quux') == %w'foo-bar baz_quux' }
    end
  end

  describe '#git' do
    it 'calls git with given options' do
      git.expects(:system).with('git', 'status').then('git', 'log', '--oneline').once
      git.git(:status)

      git.expects(:system).with('git', 'log', '--oneline').once
      git.git(:log, :oneline => true)
    end

    it 'raises an error if command fails' do
      # Let's stub out the system() call to make sure it returns error
      # code and doesn't print stuff out.
      class << git
        def system(*args)
          Kernel.system('false')
        end
      end
      assert { MiniGit::GitError === rescuing { git.git(:wrong) } }
      system 'true'         # to reset $? to a clean value
    end
  end

  describe '#method_missing' do
    it 'calls out to git' do
      git.expects(:git).with(:rev_parse, :git_dir => true)
      git.rev_parse :git_dir => true
    end
  end
end
