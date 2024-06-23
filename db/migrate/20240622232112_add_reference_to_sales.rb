class AddReferenceToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :reference, :string
  end
end
