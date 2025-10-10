class ChangeTimeColumnsToStringInAttendanceRecords < ActiveRecord::Migration[7.1]
  def change
    change_column :attendance_records, :on_duty, :string
    change_column :attendance_records, :off_duty, :string
    change_column :attendance_records, :clock_in, :string
    change_column :attendance_records, :clock_out, :string
  end
end