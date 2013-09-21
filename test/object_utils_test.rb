require "helper"


class ObjectUtilsTest < MiniTest::Unit::TestCase

  include AclPermalink::Test

  test "strings with letters are acl_permalinks" do
    assert "a".acl_permalink?
  end

  test "integers should be unfriendly ids" do
    assert 1.unacl_permalink?
  end

  test "numeric strings are neither friendly nor unfriendly" do
    assert_equal nil, "1".acl_permalink?
    assert_equal nil, "1".unacl_permalink?
  end

  test "ActiveRecord::Base instances should be unacl_permalinks" do
    model_class = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      self.table_name = "authors"
    end
    assert model_class.new.unacl_permalink?
  end
end