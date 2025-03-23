class AddSmugmugStatusToGalleries < ActiveRecord::Migration[7.0]
  def change
    add_column :galleries, :smugmug_status, :string, default: 'pending'
    add_column :galleries, :smugmug_url, :string
    add_column :galleries, :smugmug_key, :string
    add_column :galleries, :last_sync_at, :datetime

    add_index :galleries, :smugmug_status
    add_index :galleries, :smugmug_key, unique: true, where: "smugmug_key IS NOT NULL"
  end
end
