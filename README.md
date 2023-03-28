# thread_local_var_accessors

Ruby gem to make `ThreadLocalVars` easy to use, with either "accessor" methods,
or instance methods.

Build Status:  [![CircleCI](https://dl.circleci.com/status-badge/img/gh/aks/thread_local_var_accessors/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/aks/thread_local_var_accessors/tree/main)

## Description

This module has methods making it easy to use the `Concurrent::ThreadLocalVar`
as instance variables.  This makes instance variables using this code as
actually thread-local, without also leaking memory over time.

See [Why Concurrent::ThreadLocalVar](https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent-ruby/concurrent/atomic/thread_local_var.rb#L10-L17) to understand why we use TLVs instead of `Thread.current.thread_variable_(set|get)`

### Class Methods

Just as Rails provides _attribute_ accessor methods, eg: `attr_accessor`,
`attr_reader`, and `attr_writer`, this module provides the following
class methods for declaring getter and setter methods based on instance
variables that use `ThreadLocalVar` (TLV) objects.

    tlv_reader :var1, :var2, ...
    tlv_writer :var3, :var4, ...
    tlv_accessor :var5, :var6, ...

- `tlv_reader` creates an instance method with the name `name`, that references
  the instance variable names '@name', which is expected to be either nil,
  or already have a `Concurrent::ThreadLocalVar` instance.

- `tlv_writer` creates an instance method with the name `name=`, which accepts a single
  argument that is the new value.  This method checks for an existing value
  on the instance variable named `@name`, which should be a
  `Concurrent::ThreadLocalVar` instance.  If `@name` value is nil, then a new
  `Concurrent::ThreadLocalVar` instance is assigned to it. In either case, the
  instance variable's TLV object is assigned the new value, which is returned.

- `tlv_accessor` - creates both a `tlv_reader` and a `tlv_writer`.

For reference, see [ThreadLocalVars](https://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent/ThreadLocalVar.html).

### Instance Methods

With the accessor methods, obtaining values and setting values
becomes very simple:

    tlv_accessor :timeout
    ...
    timeout  # fetches the current TLV value, unique to each thread
    ...
    self.timeout = 0.5  # stores the TLV value just for this thread

Alternative ways to initialize:

    tlv_set(:timeout, 0)

    tlv_set(:timeout) # ensure that @timeout is initialized to an [TLV](TLV)
    @timeout.value = 0

The following methods are used within the above reader, writer, accessor
methods:

    tlv_get(name)        - fetches the value of TLV `name`
    tlv_set(name, value) - stores the value into the TLV `name`

There is a block form to `tls_set`:

    tlv_set(name) { |old_val| new_val }
   
In addition, there is also a `tlv_set_once` method that can be used to set
a TLV value only if has not currently be set already.

    ltv_set_once(name, value)
    
    ltv_set_once(name) { |old_val| new_value }

For `tlv_accessor` instance variables, it's possible to use the `||=` operator. Eg:

    tlv_accessor :timeout
    
    self.timeout ||= DEFAULT_TIMEOUT

### TLV Name Arguments

The `name` argument to `tlv_get` and `tlv_set` is the same as given on
the accessor, reader, and writer methods: either a string or symbol name,
automatically converted as needed to instance-variable syntax (eg: :@name),
and setter-method name syntax (eg :name=).


## Installation

    gem install thread_local_var_accessors

Within another app, within its `Gemfile` or `*.gemspec` file:

    gem 'thread_local_var_accessors'

Then:

    bundle install

## Usage

Use the class methods to declare instance getter and setter methods:

    tlv_reader   :name1
    tlv_writer   :name2
    tlv_accessor :name3, :name4
    
The above invocations: 
- create reader methods for `name1`, `name3`, and `name4`.
- create writer methods for `name2`, `name3`, and `name4`.

The writer methods accept a value as the second argument, or from the result of an associated block.

Note: to use the read-and-operate operators, eg: `+=`, `-=`, `||=`, etc., the object must have both a reader and writer method.  In other words, it needs to have been created as an `tlv_accessor`.

When adapting legacy code to become thread-safe, it's sometimes necessary to use the underlying instance methods:

    tlv_get(name)
    tlv_set(name, value)
    tlv_set_once(name, value)
    
Alternative block forms:

    tlv_set(name)      { |oldval| newval }
    tlv_set_once(name) { |oldval| newval }


In all cases, the `name` can be a string or symbol, with or without a leading `@`.

### Example Usage

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

The advantage of the block method, especially for `tlv_set_once`, is that the
VALUE is only evaluated when the instance variable value is being set, and, the block will receive the old value as a parameter.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

For both development and testing, the environment variables described above must be defined.

## Testing

## Continuous Integration and Deployments

This repo is configured to the [gitflow](https://datasift.github.io/gitflow/IntroducingGitFlow.html) pattern, with the `develop` branch being the _default_ branch on PRs.

The `main` branch gets updated with a PR or with a manual merge-and-push from the `develop` branch by a repo admin.

When any branch is pushed, the continuous integration with causes the branch to be tested with all of the `rspec` tests _(except the integration tests)_.

When the `main` branch is updated and after its tests pass, the `deploy` action is invoked which causes the newest build of the gem to be pushed to rubygems.org.

## Original Author:
  
    Alan K. Stebbens <aks@stebbens.org>
