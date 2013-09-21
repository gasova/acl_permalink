module AclPermalink
  # The configuration paramters passed to +acl_permalink+ will be stored in
  # this object.
  class Configuration

    # The base column or method used by AclPermalink as the basis of a friendly id
    # or slug.
    #
    # For models that don't use AclPermalink::Slugged, the base is the column that
    # is used as the AclPermalink directly. For models using AclPermalink::Slugged,
    # the base is a column or method whose value is used as the basis of the
    # slug.
    #
    # For example, if you have a model representing blog posts and that uses
    # slugs, you likely will want to use the "title" attribute as the base, and
    # AclPermalink will take care of transforming the human-readable title into
    # something suitable for use in a URL.
    #
    # @param [Symbol] A symbol referencing a column or method in the model. This
    #   value is usually set by passing it as the first argument to
    #   {AclPermalink::Base#acl_permalink acl_permalink}:
    #
    # @example
    #   class Book < ActiveRecord::Base
    #     extend AclPermalink
    #     acl_permalink :name
    #   end
    attr_accessor :base

    # The default configuration options.
    attr_reader :defaults

    # The model class that this configuration belongs to.
    # @return ActiveRecord::Base
    attr_accessor :model_class

    def initialize(model_class, values = nil)
      @model_class = model_class
      @defaults    = {}
      set values
    end

    # Lets you specify the modules to use with AclPermalink.
    #
    # This method is invoked by {AclPermalink::Base#acl_permalink acl_permalink} when
    # passing the +:use+ option, or when using {AclPermalink::Base#acl_permalink
    # acl_permalink} with a block.
    #
    # @example
    #   class Book < ActiveRecord::Base
    #     extend AclPermalink
    #     acl_permalink :name, :use => :slugged
    #   end
    # @param [#to_s,Module] *modules Arguments should be Modules, or symbols or
    #   strings that correspond with the name of a module inside the AclPermalink
    #   namespace. By default AclPermalink provides +:slugged+, +:history+,
    #   +:simple_i18n+, +:globalize+, and +:scoped+.
    def use(*modules)
      modules.to_a.flatten.compact.map do |object|
        mod = object.kind_of?(Module) ? object : AclPermalink.const_get(object.to_s.classify)
        model_class.send(:include, mod)
      end
    end

    # The column that AclPermalink will use to find the record when querying by
    # friendly id.
    #
    # This method is generally only used internally by AclPermalink.
    # @return String
    def query_field
      base.to_s
    end

    private

    def set(values)
      values and values.each {|name, value| self.send "#{name}=", value}
    end
  end
end
