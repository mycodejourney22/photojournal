class AddPhotoShootToSales < ActiveRecord::Migration[7.1]
  def change
    add_reference :sales, :photo_shoot, null: false, foreign_key: true
  end
end
