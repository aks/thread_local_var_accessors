# frozen_string_literal: true

# This module has methods making it easy to use the Concurrent::ThreadLocalVar
# as instance variables.  This makes instance variables using this code as
# actually thread-local, without also leaking memory over time.
#
# See [Why Concurrent::ThreadLocalVar](https://github.com/ruby-concurrency/concurrent-ruby/blob/master/lib/concurrent-ruby/concurrent/atomic/thread_local_var.rb#L10-L17)
# to understand why we use TLVs instead of `Thread.current.thread_variable_(set|get)`
#
# The following class methods declare `Concurrent::ThreadLocalVar` reader,
# writer, and accessors with these class methods:
#
#    tlv_reader :var1, :var2, ...
#    tlv_writer :var3, :var4, ...
#    tlv_accessor :var5, :var6, ...
#
# - `tlv_reader` creates a method with the name `name`, that references
#   the instance variable names '@name', which is expected to be either nil,
#   or already have a `Concurrent::ThreadLocalVar` instance.
#
# - `tlv_writer` creates a method with the name `name=`, which accepts a single
#   argument that is the new value.  This method checks for an existing value
#   on the instance variable named "@name", which should be a
#   `Concurrent::ThreadLocalVar` instance.  If `@name` value is nil, then a new
#   `Concurrent::ThreadLocalVar` instance is assigned to it. In either case, the
#   instance variable's TLV object is assigned the new value, which is returned.
#
# - `tlv_accessor` - creates both a `tlv_reader` and a `tlv_writer`.
#
# Just as with `attr_accessor` methods, obtaining values and setting values
# becomes very simple:
#
#     tlv_accessor :timeout
#
# Create a new TLV instance with an associated default, applied across all threads.
#
#     tlv_init :timeout, default_timeout
#
#     tlv_init :timeout { default_timeout }
#
#
# Reference the current thread value for the TLV variable:
#
#     timeout  # fetches the current TLV value, unique to each thread
#
# Assign the current thread value for the TLV variable:
#
#     self.timeout = 0.5  # stores the TLV value just for this thread
#
# Alternative ways to initialize the thread-local value:
#
#     ltv_set(:timeout, 0)
#
#     ltv_set(:timeout) # ensure that @timeout is initialized to an LTV
#
#     @timeout.value = 0
#
# Each thread-local instance can be independently assigned a value, which defaults
# to the _default_ value, or _block_, that was associated with the original
# `ThreadLocalVar.new` method.  This module also provides an easy way to do this:
#
# Initializes a TLV on the `@timeout` instance variable with a default value of
# 0.15 seconds:
#
#     tlv_init(:timeout, 0.15)
#
# This does the same, but uses a block (a Proc object) to possibly return a
# dynamic default value, as the proc is invoked each time the TLV instance is
# evaluted in a Thread.
#
#     tlv_init(:sleep_time) { computed_sleep_time }
#
# The block-proc is evaluated at the time the default value is needed, not when
# the TLV is assigned to the instance variable.  In other words, much later
# during process, when the instance variable value is evaluated, _that_ is when
# the default block is evaluated.
#
# Note that `tlv_init` does not assign the thread-local value; it assigns the
# _instance variable_ to a new TLV with the given default.  If any thread
# evaluates that instance variable, the default value will be returned unless
# and until each thread associates a new, thread-local value with the TLV.
#
# The default for an existing TLV can be redefined, using either an optional
# default value, or an optional default block.
#
#
#     tlv_set_default(:timeout, new_default)
#     tlv_set_default(:timeout) { new_default }
#
# The default for an existing TLV can also be obtained, independently of the
# current thread's local value, if any:
#
#     tlv_default(:timeout)
#
# The following methods are used within the above reader, writer, accessor
# methods:
#
#    tlv_get(name)        - fetches the value of TLV `name`
#    tlv_set(name, value) - stores the value into the TLV `name`
#
# There is a block form to `tls_set`:
#
#    tlv_set(name) { |old_val| new_val }
#
# The `name` argument to `tlv_get` and `tlv_set` is the same as given on
# the accessor, reader, writer methods: either a string or symbol name,
# automatically converted as needed to instance-variable syntax (eg: :@name),
# and setter-method name syntax (eg :name=).
#
# Example:
#
#     tlv_accessor :timeout
#
# Creates reader and writer methods called "timeout", and "timeout=",
# respectively. Both of these methods interrogate the instance variable
# "@timeout", which is initialized (by `tlv_set`) to contain a
# `Concurrent::ThreadLocalVar.new` value.
#
# The writer methods support using attached blocks to receive the current
# value, if any, and should return the value to be stored.
#
# The `timeout` reader method would look like this:
#
#     def timeout
#       instance_variable_get(:@timeout)&.value
#     end
#
# The 'timeout=' writer method would look like this:
#
#     def timeout=(value)
#       var = instance_variable_get(:@timeout) ||
#             instance_variable_get(:@timeout, Concurrent::ThreadLocalVar.new)
#       var.value = block_given? ? yield(var.value) : value
#     end
#
# Each thread referencing the instance variable, will get the same TLV object,
# but when the `.value` method is invoked, each thread will receive the initial
# value, or whatever local value may have been assigned subsequently, or the
# default, which is the same across all the threads.
#
# To obtain the value of such an TLV instance variable, do:
#
#     @timeout.value
#
# To assign a new value to an TLV instance:
#
#     @timeout.value = new_value

require 'concurrent-ruby'

# methods for making usage of ThreadLocalVars easy
module ThreadLocalVarAccessors
  # @!visibility private
  module MyRefinements
    # allow to_sym to be called on either a String or a Symbol
    refine Symbol do
      # idempotent method: :symbol.to_sym => :symbol
      def to_sym
        self
      end

      # @return [Symbol] an instance variable; eg: :name => :@name.
      #   idempotent: returns instance variable names unchanged
      def to_ivar
        to_s.to_ivar
      end
    end

    refine String do
      # @return [Symbol] an instance variable; eg: "name" => :@name.
      #   idempotent: returns instance variable names unchanged
      def to_ivar
        (start_with?('@') ? self : "@#{self}").to_sym
      end
    end
  end
  using MyRefinements

  module ClassMethods
    def tlv_reader(*names)
      names.each do |name|
        define_method(name.to_sym) { tlv_get(name) }
      end
    end

    # like attr_writer, but supports using block-values, which receive the
    # current value, returning the new value
    def tlv_writer(*names)
      names.each do |name|
        define_method("#{name}=".to_sym) do |new_value, &block|
          tlv_set(name, new_value, &block)
        end
      end
    end

    def tlv_accessor(*names)
      tlv_reader(*names)
      tlv_writer(*names)
    end
  end

  # instance methods
  def tlv_get(name)
    instance_variable_get(name.to_ivar)&.value
  end

  def tlv_set(name, value = nil, &block)
    var = instance_variable_get(name.to_ivar) || tlv_new(name)
    tlv_set_var(var, value, &block)
  end

  def tlv_set_once(name, value = nil, &block)
    if (var = instance_variable_get(name.to_ivar)) && !var.value.nil?
      var.value
    elsif var # var is set, but its value is nil
      tlv_set_var(var, value, &block)
    else # var is not set
      tlv_set_var(tlv_new(name), value, &block)
    end
  end

  # @param [String|Symbol] name the TLV name
  # @param [Object|nil] default the optional default value
  # @param [Proc] block the optional associated block
  # @return [ThreadLocalVar] a new TLV set in the instance variable
  # @example Default argument
  #   tlv_init(:ivar, default_value)
  # @example Default block
  #   tlv_init(:ivar) { default_value }
  def tlv_init(name, default=nil, &block)
    instance_variable_set(name.to_ivar, Concurrent::ThreadLocalVar.new(default, &block))
  end
  alias tlv_new tlv_init

  # Fetches the default value for the TLVar
  def tlv_default(name)
    instance_variable_get(name.to_ivar)&.send(:default)
  end

  # Sets the default value or block for the TLV _(which is applied across all threads)_
  def tlv_set_default(name, default=nil, &block)
    tlv = instance_variable_get(name.to_ivar)
    if tlv
      raise ArgumentError, "tlv_set_default: can only use a default or a block, not both" if default && block

      if block
        tlv.instance_variable_set(:@default_block, block)
        tlv.instance_variable_set(:@default, nil)
      else
        tlv.instance_variable_set(:@default_block, nil)
        tlv.instance_variable_set(:@default, default)
      end
    else
      tlv_init(name, default, &block)
    end
  end

  # @!visibility private
  def self.included(base)
    base.extend(ClassMethods)
  end

  private

  def tlv_set_var(var, value)
    var.value = block_given? ? yield(var.value) : value
  end
end
