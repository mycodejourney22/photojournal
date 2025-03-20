class AddCreditsToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :credits, :integer, default: 0, null: false
    add_column :customers, :referral_source, :string
  end
end
