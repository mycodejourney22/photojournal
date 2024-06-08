class AddUuidToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :uuid, :uuid, null: false
    add_index :appointments, :uuid, unique: true
  end
end
