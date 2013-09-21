require "helper"

class SimpleI18nTest < MiniTest::Unit::TestCase
  include AclPermalink::Test

  class Journalist < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :name, :use => :simple_i18n
  end

  def setup
    I18n.locale = :en
  end

  test "acl_permalink should return the current locale's slug" do
    journalist = Journalist.new(:name => "John Doe")
    journalist.slug_es = "juan-fulano"
    journalist.valid?
    I18n.with_locale(I18n.default_locale) do
      assert_equal "john-doe", journalist.acl_permalink
    end
    I18n.with_locale(:es) do
      assert_equal "juan-fulano", journalist.acl_permalink
    end
  end

  test "should create record with slug in column for the current locale" do
    I18n.with_locale(I18n.default_locale) do
      journalist = Journalist.new(:name => "John Doe")
      journalist.valid?
      assert_equal "john-doe", journalist.slug_en
      assert_nil journalist.slug_es
    end
    I18n.with_locale(:es) do
      journalist = Journalist.new(:name => "John Doe")
      journalist.valid?
      assert_equal "john-doe", journalist.slug_es
      assert_nil journalist.slug_en
    end
  end

  test "to_param should return the numeric id when there's no slug for the current locale" do
    transaction do
      journalist = Journalist.new(:name => "Juan Fulano")
      I18n.with_locale(:es) do
        journalist.save!
        assert_equal "juan-fulano", journalist.to_param
      end
      assert_equal journalist.id.to_s, journalist.to_param
    end
  end

  test "should set friendly id for locale" do
    transaction do
      journalist = Journalist.create!(:name => "John Smith")
      journalist.set_acl_permalink("Juan Fulano", :es)
      journalist.save!
      assert_equal "juan-fulano", journalist.slug_es
      I18n.with_locale(:es) do
        assert_equal "juan-fulano", journalist.to_param
      end
    end
  end

  test "set acl_permalink should fall back default locale when none is given" do
    transaction do
      journalist = I18n.with_locale(:es) do
        Journalist.create!(:name => "Juan Fulano")
      end
      journalist.set_acl_permalink("John Doe")
      journalist.save!
      assert_equal "john-doe", journalist.slug_en
    end
  end

  test "should sequence localized slugs" do
    transaction do
      journalist = Journalist.create!(:name => "John Smith")
      I18n.with_locale(:es) do
        Journalist.create!(:name => "Juan Fulano")
      end
      journalist.set_acl_permalink("Juan Fulano", :es)
      journalist.save!
      assert_equal "john-smith", journalist.to_param
      I18n.with_locale(:es) do
        assert_equal "juan-fulano--2", journalist.to_param
      end
    end
  end

  class RegressionTest < MiniTest::Unit::TestCase
    include AclPermalink::Test

    test "should not overwrite slugs on update_attributes" do
      transaction do
        journalist = Journalist.create!(:name => "John Smith")
        journalist.set_acl_permalink("Juan Fulano", :es)
        journalist.save!
        assert_equal "john-smith", journalist.to_param
        journalist.update_attributes :name => "Johnny Smith"
        assert_equal "johnny-smith", journalist.to_param
        I18n.with_locale(:es) do
          assert_equal "juan-fulano", journalist.to_param
        end
      end
    end
  end

  class ConfigurationTest < MiniTest::Unit::TestCase
    test "should add locale to slug column for a non-default locale" do
      I18n.with_locale :es do
        assert_equal "slug_es", Journalist.acl_permalink_config.slug_column
      end
    end

    test "should add locale to non-default slug column and non-default locale" do
      model_class = Class.new(ActiveRecord::Base) do
        self.abstract_class = true
        extend AclPermalink
        acl_permalink :name, :use => :simple_i18n, :slug_column => :foo
      end
      I18n.with_locale :es do
        assert_equal "foo_es", model_class.acl_permalink_config.slug_column
      end
    end

    test "should add locale to slug column for default locale" do
      I18n.with_locale(I18n.default_locale) do
        assert_equal "slug_en", Journalist.acl_permalink_config.slug_column
      end
    end
  end
end
