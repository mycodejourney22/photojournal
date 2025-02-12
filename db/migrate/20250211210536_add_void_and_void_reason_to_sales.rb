class AddVoidAndVoidReasonToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :void, :boolean, default: false
    add_column :sales, :void_reason, :string
  end
end
