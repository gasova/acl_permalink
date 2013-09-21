class CreateAclPermalinkSlugs < ActiveRecord::Migration

  def self.up
    create_table :permalinks do |t|
      t.string   :slug,           :null => false
      t.integer  :sluggable_id,   :null => false
      t.string   :sluggable_type, :limit => 40
      t.string   :slug_lang,      :limit => 2
      t.datetime :created_at
    end
    add_index :permalinks, :sluggable_id
    add_index :permalinks, [:slug, :sluggable_type], :unique => true
    add_index :permalinks, :sluggable_type
  end

  def self.down
    drop_table :permalinks
  end
end
