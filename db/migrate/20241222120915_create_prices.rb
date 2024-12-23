class CreatePrices < ActiveRecord::Migration[7.1]
  def change
    create_table :prices do |t|
      t.string :name
      t.text :description
      t.decimal :amount
      t.decimal :discount
      t.integer :duration
      t.text :included
      t.string :shoot_type
      t.boolean :still_valid
      t.text :icon
      t.text :outfit

      t.timestamps
    end
  end
end
