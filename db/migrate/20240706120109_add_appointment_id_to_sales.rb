class AddAppointmentIdToSales < ActiveRecord::Migration[7.1]
  def change
    add_reference :sales, :appointment, foreign_key: true
  end
end
