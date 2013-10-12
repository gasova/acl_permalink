module AclPermalink
  module TableNamePrefix
    # Set the ActiveRecord table name prefix to acl_permalink_
    def self.initialize
      "#{ActiveRecord::Base.table_name_prefix}acl_"
    end
  end
end