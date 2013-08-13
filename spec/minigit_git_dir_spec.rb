require 'spec_helper'

describe MiniGit do
  let(:work_tree) { tmp_path.join('wt') }
  let(:git_dir) { work_tree.join('.git') }
  let(:bare_git_dir) { tmp_path.join('bare.git') }
  let(:file_in_work_tree) { work_tree.join('a_file') }

  before :all do
    git_dir.mkpath
    bare_git_dir.mkpath
    FileUtils.touch(file_in_work_tree.to_s)
  end

  describe '#find_git_dir' do
    let(:git) { MiniGit.new }

    before :each do
      MiniGit.stubs(:run)
    end

    def rev_parse_returns(*rv)
      MiniGit::Spec::EXECUTOR.expects(:call).
        with('git', 'rev-parse', '--git-dir', '--show-toplevel', :capture_stdout => true).
        returns( rv.map{|v| "#{v}\n"}.join )
    end

    it "Returns a pair of pathnames by running `git rev-parse`" do
      rev_parse_returns(git_dir, work_tree)
      assert { git.find_git_dir('.') == [ git_dir.realpath.to_s, work_tree.realpath.to_s ] }
    end

    it "returns only a single pathname when only one pathname returned" do
      rev_parse_returns(bare_git_dir)
      assert { git.find_git_dir('.') == [ bare_git_dir.realpath.to_s ] }
    end

    it 'works fine with relative pathnames' do
      rev_parse_returns('.git')
      assert { git.find_git_dir(work_tree.to_s) == [ git_dir.realpath.to_s ] }

      rev_parse_returns('.git')
      assert { git.find_git_dir(work_tree.relative_path_from(Pathname.getwd).to_s) == [ git_dir.realpath.to_s ] }
    end

    it 'works fine when given a file' do
      rev_parse_returns('.git', '.')
      assert { git.find_git_dir(file_in_work_tree.to_s) == [ git_dir.realpath.to_s, work_tree.realpath.to_s ] }
    end

    it "throws an error when given a nonexistent path" do
      assert { ArgumentError === rescuing { git.find_git_dir('/does/not/exist') } }
    end

    it "throws an error when git returns error code" do
      MiniGit::Spec::EXECUTOR.expects(:call).
        with('git', 'rev-parse', '--git-dir', '--show-toplevel', :capture_stdout => true).
        raises(MiniGit::Executors::ExecuteError)
      assert { ArgumentError === rescuing { git.find_git_dir('.') } }
    end
  end

  describe '#initialize' do
    it "doesn't set @git_dir or @work_tree when not given arguments" do
      MiniGit.any_instance.expects(:find_git_dir).never
      git = MiniGit.new
      assert { git.git_dir.nil? }
      assert { git.git_work_tree.nil? }
    end

    it 'calls find_git_dir when given a path' do
      MiniGit.any_instance.expects(:find_git_dir).once.returns( [ git_dir.realpath.to_s, work_tree.realpath.to_s ] )
      git = MiniGit.new('.')
      assert { git.git_dir == git_dir.realpath.to_s }
      assert { git.git_work_tree == work_tree.realpath.to_s }
    end

    it "sets only git_dir when find_git_dir doesn't return work tree" do
      MiniGit.any_instance.expects(:find_git_dir).once.returns( [ bare_git_dir.realpath.to_s ] )
      git = MiniGit.new('.')
      assert { git.git_dir == bare_git_dir.realpath.to_s }
      assert { git.git_work_tree.nil? }
    end
  end

  describe '#git' do
    class MiniGitEnvPeek < MiniGit
      @executor = Proc.new { Hash[ENV] }
    end

    it 'Calls system() with GIT_DIR and GIT_WORK_TREE environment variables set' do
      assert { ENV['GIT_DIR'].nil? }
      assert { ENV['GIT_WORK_TREE'].nil? }

      MiniGitEnvPeek.any_instance.expects(:find_git_dir).once.returns( [ git_dir.realpath.to_s, work_tree.realpath.to_s ] )
      git = MiniGitEnvPeek.new('.')
      env = git.status
      assert { env['GIT_DIR'] == git_dir.realpath.to_s }
      assert { env['GIT_WORK_TREE'] == work_tree.realpath.to_s }

      MiniGitEnvPeek.any_instance.expects(:find_git_dir).once.returns( [ bare_git_dir.realpath.to_s ] )
      git = MiniGitEnvPeek.new('.')
      env = git.status
      assert { env['GIT_DIR'] == bare_git_dir.realpath.to_s }
      assert { env['GIT_WORK_TREE'].nil? }

      git = MiniGitEnvPeek.new
      env = git.status
      assert { env['GIT_DIR'].nil? }
      assert { env['GIT_WORK_TREE'].nil? }

      assert { ENV['GIT_DIR'].nil? }
      assert { ENV['GIT_WORK_TREE'].nil? }
    end
  end
end
