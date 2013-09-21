module AclPermalink

=begin

== Reserved Words

The {AclPermalink::Reserved Reserved} module adds the ability to exlude a list of
words from use as AclPermalink slugs.

By default, AclPermalink reserves the words "new" and "edit" when this module is
included. You can configure this globally by using {AclPermalink.defaults
AclPermalink.defaults}:

  AclPermalink.defaults do |config|
    config.use :reserved
    # Reserve words for English and Spanish URLs
    config.reserved_words = %w(new edit nueva nuevo editar)
  end

Note that the error message will appear on the field +:acl_permalink+. If you are
using Rails's scaffolded form errors display, then it will have no field to
highlight. If you'd like to change this so that scaffolding works as expected,
one way to accomplish this is to move the error message to a different field.
For example:

  class Person < ActiveRecord::Base
    extend AclPermalink
    acl_permalink :name, use: :slugged

    after_validation :move_acl_permalink_error_to_name

    def move_acl_permalink_error_to_name
      errors.add :name, *errors.delete(:acl_permalink) if errors[:acl_permalink].present?
    end
  end

=end
  module Reserved

    # When included, this module adds configuration options to the model class's
    # acl_permalink_config.
    def self.included(model_class)
      model_class.class_eval do
        acl_permalink_config.class.send :include, Reserved::Configuration
        acl_permalink_config.defaults[:reserved_words] ||= ["new", "edit"]
      end
    end

    # This module adds the +:reserved_words+ configuration option to
    # {AclPermalink::Configuration AclPermalink::Configuration}.
    module Configuration
      attr_writer :reserved_words

      # Overrides {AclPermalink::Configuration#base} to add a validation to the
      # model class.
      def base=(base)
        super
        reserved_words = model_class.acl_permalink_config.reserved_words
        model_class.validates_exclusion_of :acl_permalink, :in => reserved_words
      end

      # An array of words forbidden as slugs.
      def reserved_words
        @reserved_words ||= @defaults[:reserved_words]
      end
    end
  end
end
