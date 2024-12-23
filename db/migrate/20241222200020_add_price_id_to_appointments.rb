class AddPriceIdToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_reference :appointments, :price, null: true, foreign_key: true
  end
end
