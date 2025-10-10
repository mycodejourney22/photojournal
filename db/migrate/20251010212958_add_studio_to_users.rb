class AddStudioToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :studio, foreign_key: true, null: true
    add_index :users, [:role, :studio_id]
  end
end
