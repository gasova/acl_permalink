module AclPermalink
  # A AclPermalink slug stored in an external table.
  #
  # @see AclPermalink::History
  class Slug < ActiveRecord::Base
    belongs_to :sluggable, :polymorphic => true
	set_table_name "permalinks"
    def to_param
      slug
    end

  end
end
