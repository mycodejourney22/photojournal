class AddReferralSourceToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :referral_source, :string
  end
end
