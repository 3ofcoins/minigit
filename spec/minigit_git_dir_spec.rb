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
      Mixlib::ShellOut.any_instance.stubs(:run_command)
      Mixlib::ShellOut.any_instance.stubs(:error!)
    end

    it "Returns a pair of pathnames by running `git rev-parse`" do
      Mixlib::ShellOut.any_instance.stubs(:stdout).returns("#{git_dir}\n#{work_tree}\n")
      assert { git.find_git_dir('.') == [ git_dir.realpath.to_s, work_tree.realpath.to_s ] }
    end

    it "returns only a single pathname when only one pathname returned" do
      Mixlib::ShellOut.any_instance.stubs(:stdout).returns("#{bare_git_dir}\n")
      assert { git.find_git_dir('.') == [ bare_git_dir.realpath.to_s ] }
    end

    it 'works fine with relative pathnames' do
      Mixlib::ShellOut.any_instance.stubs(:stdout).returns(".git\n")
      assert { git.find_git_dir(work_tree.to_s) == [ git_dir.realpath.to_s ] }

      Mixlib::ShellOut.any_instance.stubs(:stdout).returns(".git\n")
      assert { git.find_git_dir(work_tree.relative_path_from(Pathname.getwd).to_s) == [ git_dir.realpath.to_s ] }
    end

    it 'works fine when given a file' do
      Mixlib::ShellOut.any_instance.stubs(:stdout).returns(".git\n.\n")
      assert { git.find_git_dir(file_in_work_tree.to_s) == [ git_dir.realpath.to_s, work_tree.realpath.to_s ] }
    end

    it "throws an error when given a nonexistent path" do
      assert { ArgumentError === rescuing { git.find_git_dir('/does/not/exist') } }
    end

    it "throws an error when git returns error code" do
      Mixlib::ShellOut.any_instance.stubs(:error!).raises(Mixlib::ShellOut::ShellCommandFailed)
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
    it 'Calls system() with GIT_DIR and GIT_WORK_TREE environment variables set' do
      git = MiniGit.new
      git.expects(:system).with({'GIT_DIR' => nil, 'GIT_WORK_TREE' => nil}, 'git', 'status')
      git.status

      MiniGit.any_instance.expects(:find_git_dir).once.returns( [ bare_git_dir.realpath.to_s ] )
      git = MiniGit.new('.')
      git.expects(:system).with({'GIT_DIR' => bare_git_dir.realpath.to_s, 'GIT_WORK_TREE' => nil}, 'git', 'status')
      git.status

      MiniGit.any_instance.expects(:find_git_dir).once.returns( [ git_dir.realpath.to_s, work_tree.realpath.to_s ] )
      git = MiniGit.new('.')
      git.expects(:system).with({'GIT_DIR' => git_dir.realpath.to_s, 'GIT_WORK_TREE' => work_tree.realpath.to_s}, 'git', 'status')
      git.status

    end
  end
end
