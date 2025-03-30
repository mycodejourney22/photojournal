class CreateRefundRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :refund_requests do |t|
      t.references :appointment, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.string :reason, null: false
      t.decimal :refund_amount, precision: 10, scale: 2, null: false
      t.text :customer_notes
      t.text :admin_notes
      t.string :account_name, null: false
      t.string :account_number, null: false
      t.string :bank_name, null: false
      t.references :processed_by, foreign_key: { to_table: :users }, null: true
      t.datetime :processed_at

      t.timestamps
    end

    add_index :refund_requests, :status

  end
end
