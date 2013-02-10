# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'minigit/version'

Gem::Specification.new do |gem|
  gem.name          = "minigit"
  gem.version       = MiniGit::VERSION
  gem.authors       = ["Maciej Pasternacki"]
  gem.email         = ["maciej@pasternacki.net"]
  gem.description   = 'A simple Ruby interface for Git'
  gem.summary       = 'A simple Ruby interface for Git'
  gem.homepage      = "https://github.com/3ofcoins/minigit"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'mixlib-shellout'

  gem.add_development_dependency 'wrong', '>= 0.7.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'simplecov'
end
