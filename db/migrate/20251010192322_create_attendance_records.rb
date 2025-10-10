class CreateAttendanceRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :attendance_records do |t|
      t.string :ac_no
      t.string :staff_name, null: false
      t.date :attendance_date, null: false
      t.time :on_duty
      t.time :off_duty
      t.time :clock_in
      t.time :clock_out
      t.string :work_time
      t.string :before_ot
      t.string :after_ot
      t.string :ndays_ot
      t.string :weekend_ot
      t.string :holiday_ot
      t.string :total_ot
      t.text :memo
      t.references :user, null: false, foreign_key: true # who uploaded it
      t.string :studio_location # ikeja, surulere, ajah
      t.integer :upload_batch_id # to group records from same upload

      t.timestamps
    end

    add_index :attendance_records, :staff_name
    add_index :attendance_records, :attendance_date
    add_index :attendance_records, :studio_location
    add_index :attendance_records, [:ac_no, :attendance_date], unique: true
  end
end