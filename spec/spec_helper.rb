# frozen_string_literal: true

$LOAD_PATH << File.expand_path(File.join(__dir__, '..'))

require 'lib/thread_local_var_accessors'

# In order for simplecov to work correctly, it *must* be loaded before any other libraries
# are loaded.  So, that's why it's here, up front.  Simplecov is started only if `CODE_COVERAGE`
# is set to a truthy value.

require 'simplecov'
if %w[1 true yes on].include?(ENV.fetch('CODE_COVERAGE', 'no'))
  SimpleCov.add_filter 'spec' # we don't need coverage on our specs or any supporting files
  SimpleCov.add_filter 'bin/ecrion' # ecrion is a test tool; don't analyze its coverage
  SimpleCov.add_filter 'lib/ecrion/' # these files are part of the ecrion test tool
  SimpleCov.start
end

require "bundler/setup"
require 'rspec'

RSpec.configure do |config|
  # If we're running just one spec, use doc format automatically
  config.default_formatter = 'doc' if config.files_to_run.one?

  # make the pending color work better than :yellow
  config.pending_color = :magenta

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Do not run disabled examples unless -t disabled on the command line
  config.filter_run_excluding disabled: true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
