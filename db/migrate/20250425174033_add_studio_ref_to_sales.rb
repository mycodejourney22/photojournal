class AddStudioRefToSales < ActiveRecord::Migration[7.1]
  def change
    add_reference :sales, :studio, null: true, foreign_key: true
  end
end
