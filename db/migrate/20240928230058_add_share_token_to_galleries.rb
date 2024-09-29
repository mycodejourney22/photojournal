class AddShareTokenToGalleries < ActiveRecord::Migration[7.1]
  def change
    add_column :galleries, :share_token, :string
  end
end
