class AddParentCodeToReferrals < ActiveRecord::Migration[7.1]
  def change
    add_column :referrals, :parent_code, :string
    add_index :referrals, :parent_code
  end
end
