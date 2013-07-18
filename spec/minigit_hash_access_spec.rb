require 'spec_helper'

describe MiniGit do
  let(:git) { MiniGit::new }

  describe '#[]' do
    it 'returns nil if the passed in attribute has no value' do
      MiniGit::Capturing.any_instance.
        expects(:system).with('git', 'config', 'foo.bar').
        at_least_once.
        raises(MiniGit::GitError)
      assert { git['foo.bar'] == nil }
    end

    it 'returns a stripped configuration value if it exists' do
      MiniGit::Capturing.any_instance.
        expects(:system).with('git', 'config', 'foo.baz').
        at_least_once.
        returns("whatever\n")
      assert { git['foo.baz'] == "whatever" }
    end
  end

  describe '.[]' do
    it 'returns nil if the passed in attribute has no value for class instance' do
      MiniGit::Capturing.any_instance.
        expects(:system).with('git', 'config', 'foo.bar').
        at_least_once.
        raises(MiniGit::GitError)
      assert { MiniGit['foo.bar'] == nil }
    end

    it 'returns a stripped configuration value if it exists for class instance' do
      MiniGit::Capturing.any_instance.
        expects(:system).with('git', 'config', 'foo.baz').
        at_least_once.
        returns("whatever\n")
      assert { MiniGit['foo.baz'] == "whatever" }
    end
  end

  describe '#[]=' do
    it 'assigns value to a git config attribute' do
      MiniGit.any_instance.
        expects(:system).with('git', 'config', 'bar.baz', 'foo')
      git['bar.baz'] = 'foo'
    end
  end

  describe '.[]=' do
    it 'assigns value to a git config attribute for class instance' do
      MiniGit.any_instance.
        expects(:system).with('git', 'config', 'bar.baz', 'foo')
      MiniGit['bar.baz'] = 'foo'
    end
  end
end
