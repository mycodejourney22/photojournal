class CreateAppointmentNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :appointment_notes do |t|
      t.references :appointment, null: false, foreign_key: true
      t.text :content, null: false
      t.string :note_type, null: false # 'pre_shoot', 'post_shoot', 'editing', 'general'
      t.string :title # Optional title for the note
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.integer :priority, default: 1 # 1 = low, 2 = medium, 3 = high
      
      t.timestamps
    end
    
    add_index :appointment_notes, [:appointment_id, :note_type], name: 'idx_appointment_notes_on_appointment_and_type'
    add_index :appointment_notes, :created_by_id, name: 'idx_appointment_notes_on_created_by'
  end
end