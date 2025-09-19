# db/migrate/create_editor_assignments.rb
class CreateEditorAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :editor_assignments do |t|
      t.references :photo_shoot, null: false, foreign_key: { to_table: :photo_shoots }
      t.references :editor, null: false, foreign_key: { to_table: :staffs }
      t.references :assigned_by, null: true, foreign_key: { to_table: :staffs }
      t.datetime :assigned_at, null: false
      t.string :status, default: 'active', null: false
      t.text :notes # Optional: for assignment notes
      
      t.timestamps
    end
    
    # Indexes for common queries
    add_index :editor_assignments, [:editor_id, :assigned_at]
    add_index :editor_assignments, [:photo_shoot_id, :status]
    add_index :editor_assignments, [:assigned_at]
  end
end