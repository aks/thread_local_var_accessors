# Rakefile for thread_local_var_accessors
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

namespace :spec do
  desc 'run tests with code coverage'
  task :coverage do
    sh 'COVERAGE=1 bundle exec rake spec'
  end
end

task build:   %i[bundle:add_linux]
task install: %i[build spec]
task release: %i[build spec]

# Local CI testing

namespace :ci do
  desc 'Check CIRCLECI config'
  task :check do
    sh 'circleci config validate', verbose: true
  end

  desc 'Run CIRCLECI config locally'
  task :local do
    sh 'circleci local execute', verbose: true
  end
end

namespace :bundle do
  desc 'add linux platform to Gemfile.lock'
  task :add_linux do
    sh "grep -s 'x86_64-linux' Gemfile.lock >/dev/null || bundle lock --add-platform x86_64-linux"
  end
end

# add spec unit tests

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc 'run Simplecov'
  task :coverage do
    sh 'CODE_COVERAGE=1 bundle exec rake spec'
  end
end

# add yard task

YARD::Rake::YardocTask.new do |t|
  t.files = ['README.md', 'lib/**/*.rb']
  t.stats_options = ['--list-undoc']
end

task default: :spec
