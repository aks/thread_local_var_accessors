# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'thread_local_var_accessors/version'

Gem::Specification.new do |s|
  s.name          = 'thread_local_var_accessors'
  s.version       = ThreadLocalVarAccessors::VERSION
  s.authors       = ['Alan Stebbens']
  s.email         = ['alan.stebbens@procore.com']
  s.homepage      = 'https://github.com/aks/thread_local_var_accessors'
  s.licenses      = ['MIT']
  s.summary       = '[summary]'
  s.description   = '[description]'

  s.files         = Dir.glob('{bin/*,lib/**/*,[A-Z]*}')
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
end
