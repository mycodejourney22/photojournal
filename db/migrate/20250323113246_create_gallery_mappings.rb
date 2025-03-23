# db/migrate/[timestamp]_create_gallery_mappings.rb
class CreateGalleryMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :gallery_mappings do |t|
      t.references :gallery, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.string :smugmug_key, null: false
      t.string :smugmug_url
      t.string :folder_path
      t.integer :status, default: 0
      t.text :error_message
      t.string :share_token
      t.string :share_url
      t.datetime :share_token_expires_at
      t.integer :views_count, default: 0
      t.datetime :last_accessed_at
      t.jsonb :metadata

      t.timestamps
    end

    add_index :gallery_mappings, :smugmug_key, unique: true
    add_index :gallery_mappings, :status
  end
end
