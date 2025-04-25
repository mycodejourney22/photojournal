class CreateStudios < ActiveRecord::Migration[7.1]
  def change
    create_table :studios do |t|
      t.string :name, null: false
      t.string :location, null: false  
      t.string :address, null: false 
      t.string :phone, null: false
      t.string :email, null: false
      t.boolean :active, default: true
      t.text :description
      t.jsonb :settings, default: {}
      t.timestamps
    end
  end
end
