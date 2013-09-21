# encoding: utf-8

require "helper"

class TranslatedArticle < ActiveRecord::Base
  translates :slug, :title
  extend AclPermalink
  acl_permalink :title, :use => :globalize
end

class GlobalizeTest < MiniTest::Unit::TestCase
  include AclPermalink::Test

  def setup
    I18n.locale = :en
  end

  test "should find slug in current locale if locale is set, otherwise in default locale" do
    transaction do
      I18n.default_locale = :en
      article_en = I18n.with_locale(:en) { TranslatedArticle.create(:title => 'a title') }
      article_de = I18n.with_locale(:de) { TranslatedArticle.create(:title => 'titel') }

      I18n.with_locale(:de) {
        assert_equal TranslatedArticle.find("titel"), article_de
        assert_equal TranslatedArticle.find("a-title"), article_en
      }
    end
  end

  test "should set friendly id for locale" do
    transaction do
      article = TranslatedArticle.create!(:title => "War and Peace")
      article.set_acl_permalink("Guerra y paz", :es)
      article.save!
      article = TranslatedArticle.find('war-and-peace')
      I18n.with_locale(:es) { assert_equal "guerra-y-paz", article.acl_permalink }
      I18n.with_locale(:en) { assert_equal "war-and-peace", article.acl_permalink }
    end
  end

  # https://github.com/svenfuchs/globalize3/blob/master/test/globalize3/dynamic_finders_test.rb#L101
  # see: https://github.com/svenfuchs/globalize3/issues/100
  test "record returned by acl_permalink should have all translations" do
    transaction do
      I18n.with_locale(:en) do
        article = TranslatedArticle.create(:title => 'a title')
        Globalize.with_locale(:ja) { article.update_attributes(:title => 'タイトル') }
        article_by_acl_permalink = TranslatedArticle.find("a-title")
        article.translations.each do |translation|
          assert_includes article_by_acl_permalink.translations, translation
        end
      end
    end
  end

end
