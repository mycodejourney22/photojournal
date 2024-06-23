class ChangePhotoShootIdInSales < ActiveRecord::Migration[7.1]
  def change
    change_column_null :sales, :photo_shoot_id, true
  end
end
