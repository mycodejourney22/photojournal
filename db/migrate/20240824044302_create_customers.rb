class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :email
      t.string :phone_number
      t.date :date_of_birth
      t.integer :visits_count, default: 0

      t.timestamps
    end
    add_index :customers, :phone_number, unique: true
  end
end
