module AclPermalink
  module Base

    def acl_permalink(base = nil, options = {}, &block)
      yield acl_permalink_config if block_given?
      acl_permalink_config.use options.delete :use
      acl_permalink_config.send :set, base ? options.merge(:base => base) : options
      before_save {|rec| rec.instance_eval {@current_acl_permalink = acl_permalink}}
      include Model
    end

    def acl_permalink_config
      @acl_permalink_config ||= base_class.acl_permalink_config.dup.tap do |config|
        config.model_class = self
        @relation_class = base_class.send(:relation_class)
      end
    end

    private

    def relation #:nodoc:
      relation = relation_class.new(self, arel_table)

      if finder_needs_type_condition?
        relation.where(type_condition).create_with(inheritance_column.to_sym => sti_name)
      else
        relation
      end
    end

    def relation_class
      @relation_class or begin
        @relation_class = Class.new(relation_without_acl_permalink.class) do
          alias_method :find_one_without_acl_permalink, :find_one
          alias_method :exists_without_acl_permalink?, :exists?
          include AclPermalink::FinderMethods
        end
        # Set a name so that model instances can be marshalled. Use a
        # ridiculously long name that will not conflict with anything.
        # TODO: just use the constant, no need for the @relation_class variable.
        const_set('AclPermalinkActiveRecordRelation', @relation_class)
      end
    end
  end

  module Model

    attr_reader :current_acl_permalink

    def acl_permalink_config
      self.class.acl_permalink_config
    end

    def acl_permalink
      send acl_permalink_config.query_field
    end

    def to_param
      if diff = changes[acl_permalink_config.query_field]
        diff.first || diff.second
      else
        acl_permalink.presence || super
      end
    end
  end
end
