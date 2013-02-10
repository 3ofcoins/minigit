require 'spec_helper'

describe MiniGit do
  let(:git) { MiniGit::new }

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
