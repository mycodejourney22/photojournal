class AddStatusToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :status, :boolean, default: true
  end
end
