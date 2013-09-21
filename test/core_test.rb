require "helper"

class Book < ActiveRecord::Base
  extend AclPermalink
  acl_permalink :name
end

class Author < ActiveRecord::Base
  extend AclPermalink
  acl_permalink :name
  has_many :books
end

class CoreTest < MiniTest::Unit::TestCase

  include AclPermalink::Test
  include AclPermalink::Test::Shared::Core

  def model_class
    Author
  end

  test "models don't use acl_permalink by default" do
    assert !Class.new(ActiveRecord::Base) {
      self.abstract_class = true
    }.respond_to?(:acl_permalink)
  end

  test "model classes should have a friendly id config" do
    assert model_class.acl_permalink(:name).acl_permalink_config
  end

  test "instances should have a friendly id" do
    with_instance_of(model_class) {|record| assert record.acl_permalink}
  end

  test "instances can be marshaled when a relationship is used" do
    transaction do
      author = Author.create :name => 'Philip'
      author.books.create :name => 'my book'
      begin
        assert Marshal.load(Marshal.dump(author))
      rescue TypeError => e
        flunk(e.to_s)
      end
    end
  end
end
