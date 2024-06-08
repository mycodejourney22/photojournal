class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.string :answer
      t.integer :position
      t.string :question
      t.references :appointment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
