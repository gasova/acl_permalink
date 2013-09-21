require "helper"

class ReservedTest < MiniTest::Unit::TestCase

  include AclPermalink::Test

  class Journalist < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :name

    after_validation :move_acl_permalink_error_to_name

    def move_acl_permalink_error_to_name
      errors.add :name, *errors.delete(:acl_permalink) if errors[:acl_permalink].present?
    end
  end

  def model_class
    Journalist
  end

  test "should reserve 'new' and 'edit' by default" do
    %w(new edit).each do |word|
      transaction do
        assert_raises(ActiveRecord::RecordInvalid) {model_class.create! :name => word}
      end
    end
  end

  test "should move acl_permalink error to name" do
    with_instance_of(model_class) do |record|
      record.errors.add :name, "xxx"
      record.errors.add :acl_permalink, "yyy"
      record.move_acl_permalink_error_to_name
      assert record.errors[:name].present? && record.errors[:acl_permalink].blank?
      assert_equal 2, record.errors.count
    end
  end

end
