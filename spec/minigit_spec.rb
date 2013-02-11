require 'spec_helper'

describe MiniGit do
  GIT_ENV = { 'GIT_DIR' => nil, 'GIT_WORK_TREE' => nil }
  let(:git) { MiniGit.new }

  describe '#git_command' do
    it 'defaults to "git"' do
      assert { git.git_command == 'git' }
    end

    it 'can be overriden per instance' do
      git.git_command = 'other'
      assert { git.git_command == 'other' }
    end

    it 'specifies how git is run' do
      git.expects(:system).with(GIT_ENV, 'other', 'whatever', '--foo=bar')
      git.git_command = 'other'
      git.whatever :foo => 'bar'
    end

    it 'has precedence MiniGit -> class -> instance' do
      gc = git.capturing

      assert { git.git_command == 'git' }
      assert { gc.git_command == 'git' }

      MiniGit.git_command = 'foo'
      assert { git.git_command == 'foo' }
      assert { gc.git_command == 'foo' }

      MiniGit::Capturing.git_command = 'bar'
      assert { git.git_command == 'foo' }
      assert { gc.git_command == 'bar' }

      git.git_command = 'baz'
      assert { git.git_command == 'baz' }
      assert { gc.git_command == 'bar' }

      gc.git_command = 'quux'
      assert { git.git_command == 'baz' }
      assert { gc.git_command == 'quux' }

      MiniGit.git_command = nil
      MiniGit::Capturing.git_command = nil
    end
  end

  describe '#git' do
    it 'calls git with given options' do
      git.expects(:system).with(GIT_ENV, 'git', 'status')
      git.git(:status)

      git.expects(:system).with(GIT_ENV, 'git', 'log', '--oneline').once
      git.git(:log, :oneline => true)
    end

    it 'raises an error if command fails' do
      git.git_command = 'false'
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

  describe '#capturing' do
    it 'returns instance of MiniGit::Capturing' do
      assert { MiniGit::Capturing === git.capturing }
    end
  end

  describe '#noncapturing' do
    it 'returns instance of MiniGit' do
      assert { MiniGit === git.noncapturing }
      deny { MiniGit::Capturing == git.noncapturing }
    end
  end

  describe MiniGit::Capturing do
    let(:git) { MiniGit::Capturing.new }

    describe "#git" do
      it "calls git and returns its output as a string" do
        assert { git.git(:help) =~ /commit/ }
      end

      it 'raises an error if command fails' do
        git.git_command = 'false'
        assert { MiniGit::GitError === rescuing { git.git(:wrong) } }
      end
    end


    describe '#capturing' do
      it 'returns instance of MiniGit::Capturing' do
        assert { MiniGit::Capturing === git.capturing }
      end
    end

    describe '#noncapturing' do
      it 'returns instance of MiniGit' do
        assert { MiniGit === git.noncapturing }
        deny { MiniGit::Capturing == git.noncapturing }
      end
    end
  end

  describe '.method_missing' do
    it 'calls out to a hidden instance of self' do
      MiniGit.any_instance.expects(:system).with(GIT_ENV, 'git', 'status')
      MiniGit.status
    end
  end

  describe '.git' do
    it 'also calls out to a hidden instance of self' do
      MiniGit.any_instance.expects(:system).with(GIT_ENV, 'git', 'status')
      MiniGit.git :status
    end
  end
end
