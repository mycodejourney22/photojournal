# db/migrate/XXXXXX_add_email_preferences_to_customers.rb
class AddEmailPreferencesToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :email_opt_out, :boolean, default: false
    add_column :customers, :email_opt_out_date, :datetime
    add_column :customers, :email_preferences, :json
  end
end
