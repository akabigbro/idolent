require 'test/unit'
require 'idolent'

class IdolentTest < Test::Unit::TestCase

  class MyObject
    include Idolent
    attr_accessor :name, :version
    lazy :inner, MyObject
    lazy_array :objects, MyObject
    lazy_hash :keyed, MyObject
  end

  def test_model_attributes
    # with stringified hash
    attr = {"name" => "my name", "version" => 2}
    obj = MyObject.new(attr)
    assert_equal attr["name"], obj.name
    assert_equal attr["version"], obj.version

    # with symbolized hash
    attr = {name: "my name", version: 2}
    obj = MyObject.new(attr)
    assert_equal attr[:name], obj.name
    assert_equal attr[:version], obj.version

    # setting attributes
    obj.name = "new name"
    assert_equal attr[:name], "new name"
    assert_equal attr[:name], obj.name
    obj.version = 99
    assert_equal attr[:version], 99
    assert_equal attr[:version], obj.version
  end

  def test_lazy_attributes
    inner = {name: "inner", version: 2}
    attr = {name: "test", version: 1, inner: inner}
    obj = MyObject.new(attr)

    # initialization
    assert_kind_of MyObject, obj.inner
    assert_equal inner[:name], obj.inner.name
    assert_equal inner[:version], obj.inner.version

    # updating
    obj.inner.version = 99
    assert_equal 99, obj.inner.version
    assert_equal 99, inner[:version]
    assert_equal inner[:version], obj.inner.version
  end

  def test_model_with_lazy_array_and_hash
    inner = {name: "inner", version: 2}
    objects = [{name: "object1", version: 1}, {name: "object2", version: 2}]
    keyed = {key1: {name: "keyed1", version: 1}, key2: {name: "keyed2", version: 2}}
    attr = {name: "test", version: 1, inner: inner, objects: objects, keyed: keyed}
    obj = MyObject.new(attr)

    # initialization
    assert_kind_of Idolent::LazyArray, obj.objects
    assert_kind_of Idolent::LazyHash, obj.keyed

    # array values
    assert_equal objects.first[:name], obj.objects.first.name
    assert_equal objects.last[:name], obj.objects.last.name
    has_objects = false
    obj.objects.each do |o|
      assert_kind_of MyObject, o
      has_objects = true
    end
    assert has_objects
    has_objects = false
    obj.objects.map do |o|
      assert_kind_of MyObject, o
      has_objects = true
    end
    assert has_objects

    # change array values
    obj.objects.first.name = "obj 1 changed"
    assert_equal "obj 1 changed", objects.first[:name]
    obj.objects.first.version = 99
    assert_equal 99, objects.first[:version]

    # add to array
    obj.objects << MyObject.new(name: "3rd", version: 3)
    assert_equal 3, objects.length
    assert_equal "3rd", objects.last[:name]
    assert_equal 3, objects.last[:version]
 
    # hash values
    assert_equal keyed[:key1][:name], obj.keyed[:key1].name
    assert_equal keyed[:key2][:name], obj.keyed[:key2].name
    has_keyed = false
    obj.keyed.each do |k,v|
      assert_kind_of MyObject, v
      has_keyed = true
    end
    assert has_keyed
    has_keyed = false
    obj.keyed.each_value do |v|
      assert_kind_of MyObject, v
      has_keyed = true
    end
    assert has_keyed

    # change hash values
    obj.keyed[:key1].name = "keyed 1 changed"
    assert_equal "keyed 1 changed", keyed[:key1][:name]
    obj.keyed[:key1].version = 99
    assert_equal 99, keyed[:key1][:version]

    # add new value
    obj.keyed[:key3] = MyObject.new(name: "keyed 3", version: 3)
    assert keyed.has_key?(:key3)
    assert_equal "keyed 3", keyed[:key3][:name]
    assert_equal 3, keyed[:key3][:version]
  end

  def test_array_methods
    array = []
    (0..4).each do |index|
      array << {name: "#{index}-name", version: index}
    end
    la = Idolent::LazyArray.new(array, MyObject)
    assert_not_nil la
    assert_equal 5, la.length

    # each
    has_each = false
    la.each do |object|
      assert_kind_of MyObject, object
      has_each = true
    end
    assert has_each

    # each_index
    has_each_index = false
    la.each_index do |index|
      object = la[index]
      assert_kind_of MyObject, object
      assert_equal "#{index}-name", object.name
      assert_equal index, object.version
      assert_equal array[index][:name], object.name
      assert_equal array[index][:version], object.version
      has_each_index = true
    end
    assert has_each_index

    la.first.name = "storage test"
    assert_equal "storage test", la.first.name
    assert_equal array.first[:name], la.first.name

    la << MyObject.new(name: "testing", version: 2)
    assert_equal 6, la.length
    assert_equal "testing", la.last.name
    assert_equal array.last[:name], la.last.name
  end
end
