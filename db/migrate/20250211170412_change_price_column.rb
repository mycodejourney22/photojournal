class ChangePriceColumn < ActiveRecord::Migration[7.1]
  def change
    change_column :prices, :included, :string
    change_column :prices, :outfit, :string
    add_column :prices, :period, :string
  end
end
