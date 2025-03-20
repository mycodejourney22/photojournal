class AddDiscountsToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :discount, :integer, default: 0
    add_column :sales, :discount_reason, :string
  end
end
