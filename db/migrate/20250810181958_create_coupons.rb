# db/migrate/xxxx_create_coupons.rb
class CreateCoupons < ActiveRecord::Migration[7.0]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :coupon_type, null: false, default: 'fixed_amount'
      t.text :description
      t.integer :discount_amount, default: 0
      t.integer :discount_percentage, default: 0
      t.integer :max_uses, default: 1000
      t.integer :usage_count, default: 0
      t.datetime :expires_at
      t.string :status, default: 'active'
      t.boolean :customer_restrictions, default: false
      t.text :campaign_notes
      t.string :minimum_amount # Optional: minimum purchase amount
      
      t.timestamps
    end
    
    add_index :coupons, :code, unique: true
    add_index :coupons, :status
    add_index :coupons, :coupon_type
    add_index :coupons, [:status, :expires_at]
  end
end