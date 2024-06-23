class AddLocationToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :location, :string
  end
end
