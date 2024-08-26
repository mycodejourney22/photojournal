class AddCustomerIdToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :customer_id, :integer
    add_index :sales, :customer_id
  end
end
