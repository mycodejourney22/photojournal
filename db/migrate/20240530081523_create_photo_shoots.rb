class CreatePhotoShoots < ActiveRecord::Migration[7.1]
  def change
    create_table :photo_shoots do |t|
      t.references :appointment, null: false, foreign_key: true
      t.date :date
      t.integer :photographer_id
      t.integer :editor_id
      t.integer :customer_service_id
      t.integer :number_of_selections
      t.string :status
      t.string :type_of_shoot
      t.integer :number_of_outfits
      t.date :date_sent
      t.decimal :payment_total
      t.string :payment_method
      t.string :payment_type
      t.string :reference

      t.timestamps
    end
  end
end
