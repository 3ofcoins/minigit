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
  end

  describe '#[]' do
    it 'returns a stripped configuration value if it exists' do
      MiniGit::Capturing.any_instance.
        expects(:system).with('git', 'config', 'foo.bar').
        at_least_once.
        returns("whatever\n")
      assert { git['foo.bar'] == "whatever" }
    end
  end

  #  describe '[]' do
  #    it 'returns nil if the passed in attribute has no value' do
  #      assert { MiniGit['foo.bar'] == nil }
  #    end
  #  end

  # describe '#[]=' do
  #   it 'assigns value to a git config attribute' do
  #     git['bar.baz'] = 'foo'
  #     MiniGit['bar.yyz'] = 'yyz'
  #     assert { git['bar.baz'] == "foo\n" }
  #     assert { MiniGit['bar.yyz'] == "yyz\n" }
  #   end
  # end

end
