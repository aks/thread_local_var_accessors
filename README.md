# thread_local_var_accessors

Ruby gem to make `ThreadLocalVars` easy to use, with either "accessor" methods,
or instance methods.

Build Status:  TBD

Just as Rails provides _attribut_ accessor methods, eg: `attr_accessor`,
`attr_reader`, and `attr_writer`, this [module](module) provides the following
class methods for declaring getter and setter methods based on instance
variables that use `ThreadLocalVar` (TLV) objects.

    tlv_accessor - create TLV reader and writer methods for each named argument
    tlv_reader   - create TLV reader methods for each named argument
    tlv_writer   - create TLV writer methods for each named argument

For reference, see [ThreadLocalVars](https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/ThreadLocalVar.html).

## Installation

    gem install thread_local_var_accessors

Within another app, within its `Gemfile` or `*.gemspec` file:

    gem '[thread_local_var_accessors](thread_local_var_accessors)'

then

    bundle install

## Usage

```ruby
require 'thread_local_var_accessors'

class MyClass
  include ThreadLocalVarAccessors

  tlv_accessor :timeout, :max_time, :count, :limit
  tlv_reader   :sleep_time
  tlv_writer   :locked

  def initialize(**args)
    self.limit      = args[:limit]
    self.timeout    = args[:timeout]
    self.max_time   = args[:max_time]
    self.sleep_time = args[:sleep_time]
  end

  def run
    while count < limit && delay_time < timeout
      ...
      self.max_time ||= DEFAULT_MAX_TIME
      ...
      sleep sleep_time
      ...
      self.locked = true
    end
  end
end
```

There may be times where you may want to use the `tlv_`-prefix methods and not use the accessors.

The following are a set of equivalencies.

```ruby
    tlv_accessor :timeout
```

produces both the reader and writer methods, using the `tlv_get` and `tlv_set` methods.

```ruby
    def timeout
      tlv_get(:timeout)
    end

    def timeout=(val)
      tlv_set(:timeout, val)
    end
```

The `tlv_get` and `tlv_set` methods fetch and set values from instance variables that hold
`ThreadLocalVar` objects, which maintain separate, distinct values for each thread.

The `tlv_set` method allows the value to be passed as a parameter, or provided in an associated block.

the `tlv_set_once` method allows an instance variable to be set once, only if it is not already set.

These are the instance methods provided by this gem:

    tlv_get(NAME)             - fetch the value from the TLV in the instance variable named NAME
    tlv_set(NAME, VALUE)      - set the value on the TLV in the instance variable named NAME
    tlv_set_once(NAME, VALUE) - set the value on the TLV in the instance variable named NAME, but only if it is not already set.
    tlv_new(NAME)             - creates a new instance variable named NAME, set to a empty `Concurrent::ThreadLocalVar`.

The `set` methods have block alternatives;

     tlv_set(NAME)      { VALUE }
     tlv_set_once(NAME) { VALUE }

The advantage of the block method, especially for `tlv_set_once`, is that the
VALUE is only evaluated when the instance variable value is being set.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

For both development and testing, the environment variables described above must be defined.

## Testing

## Continuous Integration and Deployments

This repo is configured to the [gitflow](https://datasift.github.io/gitflow/IntroducingGitFlow.html) pattern, with the `develop` branch being the _default_ branch on PRs.

The `main` branch gets updated with a PR or with a manual merge-and-push from the `develop` branch by a repo admin.

When any branch is pushed, the continuous integration with causes the branch to be tested with all of the `rspec` tests _(except the integration tests)_.

When the `main` branch is updated and after its tests pass, the `deploy` action is invoked which causes the newest build of the gem to be pushed to rubygems.org.

