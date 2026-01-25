class AddNewFieldsToTrainingEnrollments < ActiveRecord::Migration[7.1]
  def change
    # Add uuid without null constraint first
    add_column :training_enrollments, :uuid, :string

    # Backfill existing records with UUIDs
    TrainingEnrollment.reset_column_information
    TrainingEnrollment.find_each do |enrollment|
      enrollment.update_column(:uuid, SecureRandom.uuid)
    end

    # Now add the null constraint and index
    change_column_null :training_enrollments, :uuid, false
    add_index :training_enrollments, :uuid, unique: true

    # Add other columns
    add_column :training_enrollments, :payment_status, :boolean, default: false
    add_column :training_enrollments, :paid_at, :datetime
    add_reference :training_enrollments, :customer, foreign_key: true, null: true
  end
end
