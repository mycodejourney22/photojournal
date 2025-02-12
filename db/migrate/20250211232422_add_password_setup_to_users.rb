class AddPasswordSetupToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :password_setup_token, :string
    add_column :users, :password_setup_sent_at, :datetime
  end
end
