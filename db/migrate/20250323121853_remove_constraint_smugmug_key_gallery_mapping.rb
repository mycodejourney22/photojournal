class RemoveConstraintSmugmugKeyGalleryMapping < ActiveRecord::Migration[7.1]
  def change
    change_column_null :gallery_mappings, :smugmug_key, true
    remove_index :gallery_mappings, :smugmug_key, if_exists: true
  end

  # add_index :gallery_mappings, :smugmug_key, unique: true, where: "smugmug_key IS NOT NULL"
  # add_index :gallery_mappings, :status
end
