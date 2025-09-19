class AddDefaultStatusToPhotoShoots < ActiveRecord::Migration[7.1]
  def change
    change_column_default :photo_shoots, :status, from: nil, to: 'New'
  end
end
