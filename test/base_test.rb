require "helper"

class CoreTest < MiniTest::Unit::TestCase
  include AclPermalink::Test

  test "acl_permalink can be added using 'extend'" do
    klass = Class.new(ActiveRecord::Base) do
      extend AclPermalink
    end
    assert klass.respond_to? :acl_permalink
  end

  test "acl_permalink can be added using 'include'" do
    klass = Class.new(ActiveRecord::Base) do
      include AclPermalink
    end
    assert klass.respond_to? :acl_permalink
  end

  test "acl_permalink should accept a base and a hash" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend AclPermalink
      acl_permalink :foo, :use => :slugged, :slug_column => :bar
    end
    assert klass < AclPermalink::Slugged
    assert_equal :foo, klass.acl_permalink_config.base
    assert_equal :bar, klass.acl_permalink_config.slug_column
  end


  test "acl_permalink should accept a block" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend AclPermalink
      acl_permalink :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    assert klass < AclPermalink::Slugged
    assert_equal :foo, klass.acl_permalink_config.base
    assert_equal :bar, klass.acl_permalink_config.slug_column
  end

  test "the block passed to acl_permalink should be evaluated before arguments" do
    klass = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend AclPermalink
      acl_permalink :foo do |config|
        config.base = :bar
      end
    end
    assert_equal :foo, klass.acl_permalink_config.base
  end

  test "should allow defaults to be set via a block" do
    begin
      AclPermalink.defaults do |config|
        config.base = :foo
      end
      klass = Class.new(ActiveRecord::Base) do
        self.abstract_class = true
        extend AclPermalink
      end
      assert_equal :foo, klass.acl_permalink_config.base
    ensure
      AclPermalink.instance_variable_set :@defaults, nil
    end
  end
end