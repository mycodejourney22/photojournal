class CreateJobApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :job_applications do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :position
      t.string :portfolio_link
      t.text :motivation
      t.string :reference_number
      t.string :status

      t.timestamps
    end
  end
end
