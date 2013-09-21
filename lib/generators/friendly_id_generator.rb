require 'rails/generators'
require "rails/generators/active_record"

# This generator adds a migration for the {AclPermalink::History
# AclPermalink::History} addon.
class AclPermalinkGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration

  source_root File.expand_path('../../acl_permalink', __FILE__)

  # Copies the migration template to db/migrate.
  def copy_files(*args)
    migration_template 'migration.rb', 'db/migrate/create_acl_permalink_slugs.rb'
  end

end
