class CreateSales < ActiveRecord::Migration[7.1]
  def change
    create_table :sales do |t|
      t.datetime :date
      t.decimal :amount_paid
      t.string :payment_method
      t.string :payment_type
      t.string :customer_name
      t.string :customer_phone_number
      t.string :customer_service_officer_name
      t.string :product_service_name

      t.timestamps
    end
  end
end
