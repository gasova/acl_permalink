require "helper"

class Novelist < ActiveRecord::Base
  extend AclPermalink
  acl_permalink :name, :use => :slugged
end

class Novel < ActiveRecord::Base
  extend AclPermalink
  belongs_to :novelist
  belongs_to :publisher
  acl_permalink :name, :use => :scoped, :scope => [:publisher, :novelist]
end

class Publisher < ActiveRecord::Base
  has_many :novels
end

class ScopedTest < MiniTest::Unit::TestCase

  include AclPermalink::Test
  include AclPermalink::Test::Shared::Core

  def model_class
    Novel
  end

  test "should detect scope column from belongs_to relation" do
    assert_equal ["publisher_id", "novelist_id"], Novel.acl_permalink_config.scope_columns
  end

  test "should detect scope column from explicit column name" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend AclPermalink
      acl_permalink :empty, :use => :scoped, :scope => :dummy
    end
    assert_equal ["dummy"], model_class.acl_permalink_config.scope_columns
  end

  test "should allow duplicate slugs outside scope" do
    transaction do
      novel1 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "a")
      novel2 = Novel.create! :name => "a", :novelist => Novelist.create!(:name => "b")
      assert_equal novel1.acl_permalink, novel2.acl_permalink
    end
  end

  test "should not allow duplicate slugs inside scope" do
    with_instance_of Novelist do |novelist|
      novel1 = Novel.create! :name => "a", :novelist => novelist
      novel2 = Novel.create! :name => "a", :novelist => novelist
      assert novel1.acl_permalink != novel2.acl_permalink
    end
  end

  test "should raise error if used with history" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      extend AclPermalink
    end

    assert_raises RuntimeError do
      model_class.acl_permalink :name, :use => [:scoped, :history]
    end
  end

  test "should apply scope with multiple columns" do
    transaction do
      novelist = Novelist.create! :name => "a"
      publisher = Publisher.create! :name => "b"

      novel1 = Novel.create! :name => "c", :novelist => novelist, :publisher => publisher
      novel2 = Novel.create! :name => "c", :novelist => novelist, :publisher => Publisher.create(:name => "d")
      novel3 = Novel.create! :name => "c", :novelist => Novelist.create(:name => "e"), :publisher => publisher
      novel4 = Novel.create! :name => "c", :novelist => novelist, :publisher => publisher

      assert_equal novel1.acl_permalink, novel2.acl_permalink
      assert_equal novel2.acl_permalink, novel3.acl_permalink
      assert novel3.acl_permalink != novel4.acl_permalink
    end
  end
end
