module AclPermalink
  module FinderMethods

    protected

    def find_one(id)
      return super if id.unacl_permalink?
      where(@klass.acl_permalink_config.query_field => id).first or super
    end

    def exists?(id = false)
      return super if id.unacl_permalink?
      super @klass.acl_permalink_config.query_field => id
    end
  end
end
