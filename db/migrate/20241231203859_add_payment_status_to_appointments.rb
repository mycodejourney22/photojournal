class AddPaymentStatusToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :payment_status, :boolean, default: false
  end

end
