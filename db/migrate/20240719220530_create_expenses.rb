class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.date :date
      t.string :description
      t.string :category
      t.string :staff
      t.decimal :amount
      t.string :location

      t.timestamps
    end
  end
end
