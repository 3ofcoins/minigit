# Minigit

Minigit is a minimal Ruby interface for Git. It is a simple proxy that
runs Git commands, and optionally captures output. It does not provide
any abstraction provided by Grit or Git gems. It is just a simple
wrapper over `system('git ...')` call. It also allows capturing output
of Git commands.

## Installation

Add this line to your application's Gemfile:

    gem 'minigit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install minigit

## Usage

To use the library in your code, simply require it.

```ruby
require 'minigit'
```

### One-off Commands

You can run one-off commands simply by calling methods on the `MiniGit`
class:

```ruby
 MiniGit.branch # => nil (`git branch` output goes directly to terminal)
```

To capture output, use `MiniGit::Capturing`:

```ruby
 MiniGit::Capturing.branch # => "* master\n"
```

Methods are translated directly into Git commands. Arguments are
translated into command-line switches and arguments:

```ruby
MiniGit.status                  # git status
MiniGit.status :s => true       # git status -s
MiniGit.status :short => true   # git status --short
MiniGit.log :n => 5             # git log -n 5
MiniGit.log({:n => 5}, 'path/'  # git log -n 5 path/
MiniGit.ls_tree :HEAD           # git ls-tree HEAD
MiniGit.something {:a => true}, 'foo', [1, {2 => 3}, 4], 'a_b', :c_d
  # Not useful, but shows how arguments are composed and interpreted:
  # git something -a foo 1 -2 3 4 a_b c-d
```

For scripted access or to run a Git subcommand with underscore
character, use the `git` method:

```ruby
MiniGit.git :foo_bar, :baz => true  # git foo-bar --baz
MiniGit.git 'foo_bar', :baz => true # git foo_bar --baz
```

The `MiniGit` class methods call out to Git without any particular
parameters, it behaves as if you just called git in your current
directory.

### Instances

You can create instances of `MiniGit` and `MiniGit::Capturing`. If you
don't provide any arguments, the instance will behave as if the class
methods have been called - just run `git` in current directory. The
methods are also the same. If you call a `capturing` method, you get
instance of the `MiniGit::Capturing` class; if you call a `noncapturing`
method, you get instance of `MiniGit`.

```ruby
git = MiniGit.new
git.branch              # => nil (output shown to the terminal)
git.capturing.branch    # => "* master\n"
```

```ruby
cgit = MiniGit::Capturing.new
git.branch              # => "* master\n"
git.noncapturing.branch # => nil (output shown to the terminal)
```

You can also provide a path specifying the Git repo. It can be:

 * a working directory
 * a file in or subdirectory of a working directory
 * a bare repository
 * a `.git` directory (which will be trated as a bare repository)

MiniGit will find the Git directory and work tree automagically by
calling out to `git rev-parse --git-dir --show-toplevel`, will set
`git_dir` and `git_work_tree` attributes, and add them as environment
variables when calling Git to have the calls work with a specified
repository. The `git_dir` and `git_work_tree` attributes are preserved
over `#capturing` and `#noncapturing` calls.

```ruby
MiniGit.log :n => 1, :oneline => true     # 47aac92 MiniGit.git method
MiniGit.new.log :n => 1, :oneline => true # 47aac92 MiniGit.git method
MiniGit.new('../vendorificator').log :n => 1, :oneline => true
    # b485d32 Merge branch 'release/0.1.1' into develop
MiniGit.new('../vendorificator').capturing.log :n => 1, :oneline => true
    # => "b485d32 Merge branch 'release/0.1.1' into develop\n"
```

### Git command

By default, MiniGit just calls `git`. You can override the Git command
on a couple levels:

 * Instance level (when instantiating and as an attribute) will
   override Git command for that instance, and instance it creates via
   `#capturing` / `#noncapturing`:
   
```ruby
MiniGit.new(nil, :git_command => '/path/to/git')
MiniGit.new('/path/to/repo', :git_command => '/path/to/git')
```

```ruby
git = MiniGit.new
git.git_command = '/path/to/git'
```

 * Class level - when set on subclass, will be used by this class
   methods of this subclass, and as a default for instances of this
   subclass.

```ruby
class CustomGit < MiniGit
  self.git_command = '/path/to/git'
end  
CustomGit.git_command            # => "/path/to/git"
CustomGit.new.git_command        # => "/path/to/git"
CustomGit.new(nil, :git_command => '/other/git').git_command
                                 # => "/other/git"
MiniGit.new.git_command          # => "git"
MiniGit.git_command              # => "git"
MiniGit::Capturing.git_command   # => "git"
```

 * MiniGit level - Changing `MiniGit.git_command` will be used as a
   default for MiniGit itself, and for all its subclasses and subclass
   instances that don't override it.

```ruby
MiniGit.git_command = '/yet/another/git' # => "/yet/another/git"
MiniGit.new.git_command                  # => "/yet/another/git"
MiniGit::Capturing.git_command           # => "/yet/another/git"
CustomGit.git_command                    # => "/path/to/git"
CustomGit.new.git_command                # => "/path/to/git"
```

## Issues

Non-capturing MiniGit doesn't always play well when Git is configured
to use pager. You can disable it by setting `GIT_PAGER` environment
variable to an empty string:

```ruby
ENV['GIT_PAGER'] = ''
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`), together
   with specs for them
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
