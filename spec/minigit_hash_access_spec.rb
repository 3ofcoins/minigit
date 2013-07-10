require 'spec_helper'

describe MiniGit do
  let(:git) { MiniGit::new }

  describe '#[]' do
    it 'returns nil if the passed in attribute has no value' do
      assert { git['foo.bar'] == nil }
      assert { MiniGit['foo.bar'] == nil }
    end
  end

  describe '#[]=' do
    it 'assigns value to a git config attribute' do
      git['bar.baz'] = 'foo'
      MiniGit['bar.yyz'] = 'yyz'
      assert { git['bar.baz'] == "foo\n" }
      assert { MiniGit['bar.yyz'] == "yyz\n" }
    end
  end

end
