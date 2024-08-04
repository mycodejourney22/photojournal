class AddStaffIdToSales < ActiveRecord::Migration[7.1]
  def change
    add_column :sales, :staff_id, :integer
  end
end
