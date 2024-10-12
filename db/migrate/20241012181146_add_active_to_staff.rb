class AddActiveToStaff < ActiveRecord::Migration[7.1]
  def change
    add_column :staffs, :active, :boolean, default: true
  end
end
