require "helper"

class StiTest < MiniTest::Unit::TestCase

  include AclPermalink::Test
  include AclPermalink::Test::Shared::Core
  include AclPermalink::Test::Shared::Slugged

  class Journalist < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :name, :use => :slugged
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end

  test "acl_permalink should accept a base and a hash with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend AclPermalink
      acl_permalink :foo, :use => :slugged, :slug_column => :bar
    end
    klass = Class.new(abstract_klass)
    assert klass < AclPermalink::Slugged
    assert_equal :foo, klass.acl_permalink_config.base
    assert_equal :bar, klass.acl_permalink_config.slug_column
  end

  test "the configuration's model_class should be the class, not the base_class" do
    assert_equal model_class, model_class.acl_permalink_config.model_class
  end

  test "acl_permalink should accept a block with single table inheritance" do
    abstract_klass = Class.new(ActiveRecord::Base) do
      def self.table_exists?; false end
      extend AclPermalink
      acl_permalink :foo do |config|
        config.use :slugged
        config.base = :foo
        config.slug_column = :bar
      end
    end
    klass = Class.new(abstract_klass)
    assert klass < AclPermalink::Slugged
    assert_equal :foo, klass.acl_permalink_config.base
    assert_equal :bar, klass.acl_permalink_config.slug_column
  end

  test "acl_permalink slugs should not clash with eachother" do
    transaction do
      journalist  = model_class.base_class.create! :name => 'foo bar'
      editoralist = model_class.create! :name => 'foo bar'

      assert_equal 'foo-bar', journalist.slug
      assert_equal 'foo-bar--2', editoralist.slug
    end
  end

end

class StiTestWithHistory < StiTest
  class Journalist < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :name, :use => [:slugged, :history]
  end

  class Editorialist < Journalist
  end

  def model_class
    Editorialist
  end
end