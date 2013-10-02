require 'spec_helper'

describe MiniGit do
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
      git.expects(:system).with('other', 'whatever', '--foo=bar')
      git.git_command = 'other'
      git.whatever :foo => 'bar'
    end

    it 'has precedence MiniGit -> class -> instance' do
      gc = git.capturing

      assert { git.git_command == 'git' }
      assert { gc.git_command == 'git' }
      assert { MiniGit.git_command == 'git' }
      assert { MiniGit::Capturing.git_command == 'git' }

      MiniGit.git_command = 'foo'
      assert { git.git_command == 'foo' }
      assert { gc.git_command == 'foo' }
      assert { MiniGit.git_command == 'foo' }
      assert { MiniGit::Capturing.git_command == 'foo' }

      MiniGit::Capturing.git_command = 'bar'
      assert { git.git_command == 'foo' }
      assert { gc.git_command == 'bar' }
      assert { MiniGit.git_command == 'foo' }
      assert { MiniGit::Capturing.git_command == 'bar' }

      git.git_command = 'baz'
      assert { git.git_command == 'baz' }
      assert { gc.git_command == 'bar' }
      assert { MiniGit.git_command == 'foo' }
      assert { MiniGit.new.git_command == 'foo' }
      assert { MiniGit::Capturing.git_command == 'bar' }

      gc.git_command = 'quux'
      assert { git.git_command == 'baz' }
      assert { gc.git_command == 'quux' }
      assert { MiniGit.git_command == 'foo' }
      assert { MiniGit.new.git_command == 'foo' }
      assert { MiniGit::Capturing.git_command == 'bar' }
      assert { MiniGit::Capturing.new.git_command == 'bar' }

      MiniGit.git_command = nil
      MiniGit::Capturing.git_command = nil
    end
  end

  describe '#git' do
    it 'calls git with given options' do
      git.expects(:system).with('git', 'status')
      git.git(:status)

      git.expects(:system).with('git', 'log', '--oneline').once
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
        system 'true'         # to reset $? to a clean value
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
      MiniGit.any_instance.expects(:system).with('git', 'status')
      MiniGit.status
    end
  end

  describe '.git' do
    it 'also calls out to a hidden instance of self' do
      MiniGit.any_instance.expects(:system).with('git', 'status')
      MiniGit.git :status
    end
  end

  describe '.debug' do
    before { MiniGit.debug = true  }
    after  { MiniGit.debug = false }

    it 'makes MiniGit print the commands it runs' do
      git.stubs(:system)
      out, err = capture_io { git.status }
      assert { err.include?("+ git status\n") }
    end

    it 'makes MiniGit also print out rev-parse command with its directory' do
      MiniGit.any_instance.expects(:'`').
        with('git rev-parse --git-dir --show-toplevel').
        returns(".git\n/\n")
      out, err = capture_io { MiniGit.new('.') }
      assert { err.include?(
          "+ [#{Dir.pwd}] git rev-parse --git-dir --show-toplevel # => "
          ) }
    end
  end
end
