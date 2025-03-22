class CreateCreditUsages < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_usages do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.integer :amount, null: false
      t.datetime :used_at, null: false
      t.text :notes

      t.timestamps
    end

    # Add an index to help with querying credit usage history
    add_index :credit_usages, [:customer_id, :used_at]
  end
end
