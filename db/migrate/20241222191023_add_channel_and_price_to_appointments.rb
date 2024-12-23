class AddChannelAndPriceToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_column :appointments, :channel, :string
    add_column :appointments, :price, :integer
  end
end
