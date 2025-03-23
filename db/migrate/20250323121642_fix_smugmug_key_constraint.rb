class FixSmugmugKeyConstraint < ActiveRecord::Migration[7.1]
  def change
    # Change smugmug_key to allow NULL values
    change_column_null :gallery_mappings, :smugmug_key, true

    # Also make sure we remove any unique index on smugmug_key and replace it with a conditional one
    remove_index :gallery_mappings, :smugmug_key, if_exists: true
    add_index :gallery_mappings, :smugmug_key, unique: true, where: "smugmug_key IS NOT NULL"
  end
end
