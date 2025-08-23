class AddActionedToAppointmentNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :appointment_notes, :actioned, :boolean, default: false, null: false
    add_column :appointment_notes, :actioned_at, :datetime
    add_column :appointment_notes, :actioned_by_id, :integer
    
    add_foreign_key :appointment_notes, :users, column: :actioned_by_id
    add_index :appointment_notes, :actioned
    add_index :appointment_notes, :actioned_by_id
  end
end