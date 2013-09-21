module AclPermalink
  module Test
    module Shared

      module Slugged
        test "configuration should have a sequence_separator" do
          assert !model_class.acl_permalink_config.sequence_separator.empty?
        end

        test "should make a new slug if the acl_permalink method value has changed" do
          with_instance_of model_class do |record|
            record.name = "Changed Value"
            record.save!
            assert_equal "changed-value", record.slug
          end
        end

        test "should increment the slug sequence for duplicate friendly ids" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            assert record2.acl_permalink.match(/2\z/)
          end
        end

        test "should not add slug sequence on update after other conflicting slugs were added" do
          with_instance_of model_class do |record|
            old = record.acl_permalink
            model_class.create! :name => record.name
            record.save!
            record.reload
            assert_equal old, record.to_param
          end
        end

        test "should not increment sequence on save" do
          with_instance_of model_class do |record|
            record2 = model_class.create! :name => record.name
            record2.active = !record2.active
            record2.save!
            assert record2.acl_permalink.match(/2\z/)
          end
        end

        test "should create slug on save if the slug is nil" do
          with_instance_of model_class do |record|
            record.slug = nil
            record.save!
            assert_nil record.slug
            record.save!
            refute_nil record.slug
          end
        end

        test "when validations block save, to_param should return acl_permalink rather than nil" do
          my_model_class = Class.new(model_class)
          self.class.const_set("Foo", my_model_class)
          with_instance_of my_model_class do |record|
            record.update_attributes my_model_class.acl_permalink_config.slug_column => nil
            record = my_model_class.find(record.id)
            record.class.validate Proc.new {errors[:name] = "FAIL"}
            record.save
            assert_equal record.to_param, record.acl_permalink
          end
        end

      end

      module Core
        test "finds should respect conditions" do
          with_instance_of(model_class) do |record|
            assert_raises(ActiveRecord::RecordNotFound) do
              model_class.where("1 = 2").find record.acl_permalink
            end
          end
        end

        test "should be findable by friendly id" do
          with_instance_of(model_class) {|record| assert model_class.find record.acl_permalink}
        end

        test "should exist? by friendly id" do
          with_instance_of(model_class) do |record|
            assert model_class.exists? record.id
            assert model_class.exists? record.acl_permalink
            assert model_class.exists?({:id => record.id})
            assert model_class.exists?(['id = ?', record.id])
            assert !model_class.exists?(record.acl_permalink + "-hello")
            assert !model_class.exists?(0)
          end
        end

        test "should be findable by id as integer" do
          with_instance_of(model_class) {|record| assert model_class.find record.id.to_i}
        end

        test "should be findable by id as string" do
          with_instance_of(model_class) {|record| assert model_class.find record.id.to_s}
        end

        test "should be findable by numeric acl_permalink" do
          with_instance_of(model_class, :name => "206") {|record| assert model_class.find record.acl_permalink}
        end

        test "to_param should return the acl_permalink" do
          with_instance_of(model_class) {|record| assert_equal record.acl_permalink, record.to_param}
        end

        test "should be findable by themselves" do
          with_instance_of(model_class) {|record| assert_equal record, model_class.find(record)}
        end

        test "updating record's other values should not change the acl_permalink" do
          with_instance_of model_class do |record|
            old = record.acl_permalink
            record.update_attributes! :active => false
            assert model_class.find old
          end
        end

        test "instances found by a single id should not be read-only" do
          with_instance_of(model_class) {|record| assert !model_class.find(record.acl_permalink).readonly?}
        end

        test "failing finds with unacl_permalink should raise errors normally" do
          assert_raises(ActiveRecord::RecordNotFound) {model_class.find 0}
        end

        test "should return numeric id if the acl_permalink is nil" do
          with_instance_of(model_class) do |record|
            record.expects(:acl_permalink).returns(nil)
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return numeric id if the acl_permalink is an empty string" do
          with_instance_of(model_class) do |record|
            record.expects(:acl_permalink).returns("")
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return numeric id if the acl_permalink is blank" do
          with_instance_of(model_class) do |record|
            record.expects(:acl_permalink).returns("  ")
            assert_equal record.id.to_s, record.to_param
          end
        end

        test "should return nil for to_param with a new record" do
          assert_equal nil, model_class.new.to_param
        end
      end
    end
  end
end

