class AddIndexToAppointmentsStartTime < ActiveRecord::Migration[7.1]
  def change
    add_index :appointments, :start_time
  end
end
