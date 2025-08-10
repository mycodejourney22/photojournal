# db/migrate/xxxx_add_coupon_to_appointments.rb
class AddCouponToAppointments < ActiveRecord::Migration[7.0]
  def change
    add_column :appointments, :coupon_code, :string
    add_column :appointments, :coupon_discount, :integer, default: 0
    
    add_index :appointments, :coupon_code
  end
end