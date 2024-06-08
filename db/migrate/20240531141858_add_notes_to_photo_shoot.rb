class AddNotesToPhotoShoot < ActiveRecord::Migration[7.1]
  def change
    add_column :photo_shoots, :notes, :string
  end
end
