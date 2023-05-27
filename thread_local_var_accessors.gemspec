# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'thread_local_var_accessors/version'

Gem::Specification.new do |s|
  s.name          = 'thread_local_var_accessors'
  s.version       = ThreadLocalVarAccessors::VERSION
  s.authors       = ['Alan Stebbens']
  s.email         = ['aks@stebbens.org']
  s.homepage      = 'https://github.com/aks/thread_local_var_accessors'
  s.licenses      = ['MIT']
  s.summary       = 'Ruby gem to make ThreadLocalVars easy to use'
  s.description   = 'Provides methods to declare and use ThreadLocalVar instance variables'

  s.files         = Dir.glob('{bin/*,lib/**/*,[A-Z]*}')
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'fuubar'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec_junit'
  s.add_development_dependency 'rspec_junit_formatter'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'spring'
  s.add_development_dependency 'terminal-notifier-guard' if /Darwin/.match?(`uname -a`.strip)
  s.add_development_dependency 'yard'

  s.add_runtime_dependency  'concurrent-ruby'
end
