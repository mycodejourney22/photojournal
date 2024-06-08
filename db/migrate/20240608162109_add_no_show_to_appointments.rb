class AddNoShowToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :no_show, :boolean, default: false
  end
end
