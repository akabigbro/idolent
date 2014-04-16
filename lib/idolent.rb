module Idolent
  attr_reader :variables

  def self.included(base)
    base.extend(LazyClassMethods)
  end

  def initialize(variables = {})
    @variables = variables
  end

  def read_variable(variable)
    return @variables[variable.to_s] if @variables.has_key?(variable.to_s)
    return @variables[variable.to_sym] if @variables.has_key?(variable.to_sym)
    return nil
  end

  def update_variable(variable, value)
    @variables[variable.to_s] = value if @variables.has_key?(variable.to_s)
    @variables[variable.to_sym] = value if @variables.has_key?(variable.to_sym)
  end

  class LazyArray
    def initialize(array = [], clazz)
      raise "class #{clazz} must have a load method" unless clazz.respond_to?(:load)
      raise "class #{clazz} must have a dump method" unless clazz.respond_to?(:dump)
      @array = array
      @clazz = clazz
    end

    def method_missing(method, *args, &block)
      case method
        when :each, :select, :collect, :map, :reject, :delete_if
          @array.send(method) { |e| yield @clazz.load(e) }
        else
          @array.send(method, *args, &block)
      end
    end

    def first
      @clazz.load(@array.first)
    end

    def last
      @clazz.load(@array.last)
    end

    def [](index)
      @clazz.load(@array[index])
    end

    def []=(index, value)
      @array[index] = @clazz.dump(value)
    end

    def <<(value)
      @array << @clazz.dump(value)
    end
  end

  class LazyHash
    def initialize(hash = {}, clazz)
      raise "class #{clazz} must have a load method" unless clazz.respond_to?(:load)
      raise "class #{clazz} must have a dump method" unless clazz.respond_to?(:dump)
      @hash = hash
      @clazz = clazz
    end

    def method_missing(method, *args, &block)
      case method
        when :each, :each_pair
          @hash.send(method) { |k,v| yield k, @clazz.load(v) }
        when :each_value
          @hash.send(method) { |v| yield @clazz.load(v) }
        when :fetch
          @clazz.load(@hash.send(method, *args))
        else
          @hash.send(method, *args, &block)
      end
    end

    def [](key)
      if @hash.has_key?(key.to_s)
        @clazz.load(@hash[key.to_s])
      elsif @hash.has_key?(key.to_sym)
        @clazz.load(@hash[key.to_sym])
      else
        nil
      end
    end

    def []=(key, value)
      if @hash.has_key?(key.to_s)
        @hash[key.to_s] = @clazz.dump(value)
      elsif @hash.has_key?(key.to_sym)
        @hash[key.to_sym] = @clazz.dump(value)
      else
        @hash[key] = @clazz.dump(value)
      end
    end

    def values
      @hash.values.collect { |v| @clazz.new(v) }
    end
  end

  module LazyClassMethods
    def attr_accessor(*variables)
      variables.each do |variable|
        define_method(variable) { read_variable(variable) }
        define_method("#{variable}=".to_sym) { |value| update_variable(variable, value) }
      end
    end

    def attr_reader(*variables)
      variables.each do |variable|
        define_method(variable) { read_variable(variable) }
      end
    end

    def attr_writer(*variables)
      variables.each do |variable|
        define_method("#{variable}=".to_sym) { |value| update_variable(variable, value) }
      end
    end

    def lazy(variable, clazz, options = {})
      raise "class #{clazz} must have a load method" unless clazz.respond_to?(:load)
      raise "class #{clazz} must have a dump method" unless clazz.respond_to?(:dump)
      define_method(variable) { clazz.load(read_variable(variable)) }
      define_method("#{variable}=") { |value| update_variable(variable, clazz.dump(value)) }
    end

    def lazy_array(variable, clazz, options = {})
      raise "class #{clazz} must have a load method" unless clazz.respond_to?(:load)
      raise "class #{clazz} must have a dump method" unless clazz.respond_to?(:dump)
      define_method(variable) { LazyArray.new(read_variable(variable), clazz) }
    end

    def lazy_hash(variable, clazz, options = {})
      raise "class #{clazz} must have a load method" unless clazz.respond_to?(:load)
      raise "class #{clazz} must have a dump method" unless clazz.respond_to?(:dump)
      define_method(variable) { LazyHash.new(read_variable(variable), clazz) }
    end

    def load(o)
      self.new(o)
    end

    def dump(o)
      o.variables
    end
  end
end
