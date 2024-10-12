class CreateGadgets < ActiveRecord::Migration[7.1]
  def change
    create_table :gadgets do |t|
      t.string :name
      t.datetime :date
      t.string :location
      t.integer :amount
      t.integer :quantity
      t.string :descriptions

      t.timestamps
    end
  end
end
