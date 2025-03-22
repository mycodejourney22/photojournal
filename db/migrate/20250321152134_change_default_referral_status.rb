class ChangeDefaultReferralStatus < ActiveRecord::Migration[7.1]
  def up
    # Change the default value from 'pending' to 'active'
    change_column_default :referrals, :status, from: 'pending', to: 'active'

    # Update all existing pending referrals to active
    execute("UPDATE referrals SET status = 'active' WHERE status = 'pending'")
  end

  def down
    change_column_default :referrals, :status, from: 'active', to: 'pending'
  end
end
