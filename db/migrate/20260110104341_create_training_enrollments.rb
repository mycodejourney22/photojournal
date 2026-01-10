class CreateTrainingEnrollments < ActiveRecord::Migration[7.1]
  def change
    create_table :training_enrollments do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.string :program
      t.string :experience
      t.text :message
      t.string :status, default: 'pending'
      t.text :notes

      t.timestamps

    end

    add_index :training_enrollments, :email
    add_index :training_enrollments, :status
    add_index :training_enrollments, :program
    add_index :training_enrollments, :created_at
  end
end
