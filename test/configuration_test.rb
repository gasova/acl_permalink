require "helper"

class ConfigurationTest < MiniTest::Unit::TestCase

  include AclPermalink::Test

  def setup
    @model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end
  end

  test "should set model class on initialization" do
    config = AclPermalink::Configuration.new @model_class
    assert_equal @model_class, config.model_class
  end

  test "should set options on initialization if present" do
    config = AclPermalink::Configuration.new @model_class, :base => "hello"
    assert_equal "hello", config.base
  end

  test "should raise error if passed unrecognized option" do
    assert_raises NoMethodError do
      AclPermalink::Configuration.new @model_class, :foo => "bar"
    end
  end

  test "#use should accept a name that resolves to a module" do
    refute @model_class < AclPermalink::Slugged
    @model_class.class_eval do
      extend AclPermalink
      acl_permalink :hello, :use => :slugged
    end
    assert @model_class < AclPermalink::Slugged
  end

  test "#use should accept a module" do
    my_module = Module.new
    refute @model_class < my_module
    @model_class.class_eval do
      extend AclPermalink
      acl_permalink :hello, :use => my_module
    end
    assert @model_class < my_module
  end

end
