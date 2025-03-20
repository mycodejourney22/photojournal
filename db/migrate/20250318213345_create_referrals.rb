class CreateReferrals < ActiveRecord::Migration[7.1]
  def change
    create_table :referrals do |t|

      t.references :referrer, null: false, foreign_key: { to_table: :customers }
      t.references :referred, foreign_key: { to_table: :customers }
      t.string :code, null: false, index: { unique: true }
      t.string :status, null: false, default: 'pending'
      t.datetime :converted_at
      t.datetime :rewarded_at
      t.datetime :expires_at
      t.integer :reward_amount, default: 10000 # Default ₦10,000 credit for referrer
      t.integer :referred_discount, default: 5000

      t.timestamps
    end
  end
end
