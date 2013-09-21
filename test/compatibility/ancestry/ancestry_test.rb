require File.expand_path("../../../helper", __FILE__)

require "ancestry"

ActiveRecord::Migration.create_table("things") do |t|
  t.string  :name
  t.string  :slug
  t.string :ancestry
end
ActiveRecord::Migration.add_index :things, :ancestry

class Thing < ActiveRecord::Base
  extend AclPermalink
  acl_permalink do |config|
    config.use :slugged
    config.use :scoped
    config.base  = :name
    config.scope = :ancestry
  end
  has_ancestry
end

class AncestryTest < MiniTest::Unit::TestCase
  include AclPermalink::Test

  test "should sequence slugs when scoped by ancestry" do
    3.times.inject([]) do |memo, _|
      memo << Thing.create!(:name => "a", :parent => memo.last)
    end.each do |thing|
      assert_equal "a", thing.acl_permalink
    end
  end
end

