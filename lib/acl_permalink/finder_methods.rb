module AclPermalink
  # These methods will be added to the model's {AclPermalink::Base#relation_class relation_class}.
  module FinderMethods

    protected

    # AclPermalink overrides this method to make it possible to use friendly id's
    # identically to numeric ids in finders.
    #
    # @example
    #  person = Person.find(123)
    #  person = Person.find("joe")
    #
    # @see AclPermalink::ObjectUtils
    def find_one(id)
      return super if id.unacl_permalink?
      where(@klass.acl_permalink_config.query_field => id).first or super
    end

    # AclPermalink overrides this method to make it possible to use friendly id's
    # identically to numeric ids in finders.
    #
    # @example
    #  person = Person.exists?(123)
    #  person = Person.exists?("joe")
    #  person = Person.exists?({:name => 'joe'})
    #  person = Person.exists?(['name = ?', 'joe'])
    #
    # @see AclPermalink::ObjectUtils
    def exists?(id = false)
      return super if id.unacl_permalink?
      super @klass.acl_permalink_config.query_field => id
    end
  end
end
