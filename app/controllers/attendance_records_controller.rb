# app/controllers/attendance_records_controller.rb
class AttendanceRecordsController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized
    after_action :verify_policy_scoped, only: [:index, :report]

    def index
        authorize AttendanceRecord
        @attendance_records = policy_scope(AttendanceRecord).recent

        # Apply filters if present
        @attendance_records = @attendance_records.by_staff(params[:staff_name]) if params[:staff_name].present?

        # Only admins can filter by location (managers are already scoped to their studio)
        if (current_user.admin? || current_user.super_admin?) && params[:location].present?
          @attendance_records = @attendance_records.by_location(params[:location])
        end

        if params[:start_date].present? && params[:end_date].present?
          @attendance_records = @attendance_records.by_date_range(params[:start_date], params[:end_date])
        elsif params[:month].present? && params[:year].present?
          @attendance_records = @attendance_records.by_month(params[:month], params[:year])
        end

        @attendance_records = @attendance_records.page(params[:page]).per(50)

        # Get unique staff names for filter dropdown (scoped to what user can see)
        # Use pluck with distinct to avoid ORDER BY conflict
        @staff_names = policy_scope(AttendanceRecord).distinct.order(:staff_name).pluck(:staff_name)
      end

    def new
      authorize AttendanceRecord
      @attendance_record = AttendanceRecord.new
    end

    def upload
      authorize AttendanceRecord
      # Show upload form
    end

    def import
      authorize AttendanceRecord
      unless params[:file].present?
        redirect_to upload_attendance_records_path, alert: 'Please select a file to upload'
        return
      end

      file = params[:file]
      studio_location = params[:studio_location]&.downcase

      # If user is a manager, override studio_location with their assigned studio
      if current_user.manager? && current_user.studio_id.present?
        studio = Studio.find_by(id: current_user.studio_id)
        studio_location = studio&.location&.downcase
      end

      begin
        require 'csv'

        Rails.logger.info "Processing file: #{file.original_filename}"

        # First try with Roo
        spreadsheet = nil
        use_csv = false

        begin
          # Try xlsx first (most common)
          spreadsheet = Roo::Excelx.new(file.path)
          Rails.logger.info "Opened as XLSX format"
        rescue => e
          Rails.logger.info "Not XLSX format, trying XLS: #{e.message}"
          begin
            spreadsheet = Roo::Excel.new(file.path)
            Rails.logger.info "Opened as XLS format"
          rescue => e2
            Rails.logger.info "Failed Excel formats, trying CSV export: #{e2.message}"
            use_csv = true
          end
        end

        # If Excel parsing failed, ask user to export as CSV
        if use_csv
          redirect_to upload_attendance_records_path,
                      alert: "Unable to read this Excel file. Please open it in Excel and save as .xlsx format, then try uploading again."
          return
        end

        Rails.logger.info "Spreadsheet loaded. Rows: #{spreadsheet.last_row}"

        # Generate batch ID for this upload
        upload_batch_id = Time.current.to_i

        imported_count = 0
        errors = []

        # Start from row 2 (skip header row)
        (2..spreadsheet.last_row).each do |row_num|
          row = spreadsheet.row(row_num)

          # Skip empty rows
          next if row.compact.empty?

          attendance_data = {
            ac_no: row[0].to_s,
            staff_name: row[1].to_s.strip,
            attendance_date: parse_date_from_excel(row[2]),
            # on_duty: format_time_string(row[4]),
            # off_duty: format_time_string(row[5]),
            clock_in: format_time_string(row[3]),
            clock_out: format_time_string(row[4]),
            # work_time: row[8].to_s,
            # before_ot: row[9].to_s,
            # after_ot: row[10].to_s,
            # ndays_ot: row[11].to_s,
            # weekend_ot: row[12].to_s,
            # holiday_ot: row[13].to_s,
            # total_ot: row[14].to_s,
            # memo: row[15].to_s,
            user_id: current_user.id,
            studio_location: studio_location,
            upload_batch_id: upload_batch_id
          }

          record = AttendanceRecord.new(attendance_data)

          if record.save
            imported_count += 1
          else
            errors << "Row #{row_num}: #{record.errors.full_messages.join(', ')}"
          end
        end

        Rails.logger.info "Import complete. Imported: #{imported_count}, Errors: #{errors.count}"
        Rails.logger.info "Import complete. Imported: #{imported_count}, Errors: #{errors.join('; ')}" if errors.any?


        if errors.any?
          flash[:warning] = "Imported #{imported_count} records with #{errors.count} errors: #{errors.first(5).join('; ')}"
        else
          flash[:notice] = "Successfully imported #{imported_count} attendance records"
        end

        redirect_to attendance_records_path

      rescue LoadError => e
        Rails.logger.error "Roo gem not found: #{e.message}"
        redirect_to upload_attendance_records_path, alert: "Please install the 'roo' gem: Add 'gem \"roo\"' to your Gemfile and run 'bundle install'"
      rescue => e
        Rails.logger.error "Import error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to upload_attendance_records_path, alert: "Error processing file: #{e.message}"
      end
    end

    def report
      authorize AttendanceRecord
      # Set date range with defaults
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

      # Get location filter
      location = params[:location]
      location = nil if location == 'All Locations'

      # Base query with policy scope
      @records = policy_scope(AttendanceRecord).by_date_range(@start_date, @end_date)

      # Apply location filter only if user is admin (managers are already scoped)
      if (current_user.admin? || current_user.super_admin?) && location.present?
        @records = @records.by_location(location.downcase)
      end

      # Calculate summary stats
      @total_staff = @records.distinct.count(:staff_name)
      @total_attendance_days = @records.count

      # Calculate average work hours
      total_hours = 0
      count = 0
      @records.each do |record|
        if record.work_time.present?
          hours = calculate_hours_from_duration(record.work_time)
          total_hours += hours if hours > 0
          count += 1
        end
      end
      @avg_work_hours = count > 0 ? (total_hours / count).round(1) : 0

      # Count late arrivals (after 9:00 AM)
      @late_arrivals_count = @records.select { |r| check_if_late(r.clock_in) }.count

      # Staff summary grouped by name
      staff_data = @records.group_by(&:staff_name)
      @staff_summary = staff_data.map do |name, records|
        late_count = records.count { |r| check_if_late(r.clock_in) }
        early_departures = records.count { |r| check_if_early_departure(r.clock_out) }

        # Calculate average hours
        hours_sum = 0
        hours_count = 0
        records.each do |r|
          if r.work_time.present?
            hours = calculate_hours_from_duration(r.work_time)
            hours_sum += hours if hours > 0
            hours_count += 1
          end
        end
        avg_hours = hours_count > 0 ? (hours_sum / hours_count).round(1) : 0

        {
          name: name,
          days_worked: records.count,
          avg_hours: avg_hours,
          late_count: late_count,
          early_departures: early_departures,
          location: records.first.studio_location
        }
      end.sort_by { |s| -s[:days_worked] }

      # Most punctual staff (least late arrivals)
      @most_punctual = @staff_summary.select { |s| s[:days_worked] >= 3 }.map do |s|
        on_time_count = s[:days_worked] - s[:late_count]
        on_time_rate = ((on_time_count.to_f / s[:days_worked]) * 100).round(0)
        s.merge(
          on_time_count: on_time_count,
          on_time_rate: on_time_rate
        )
      end.sort_by { |s| -s[:on_time_rate] }.first(5)

      # Frequently late staff
      @frequently_late = @staff_summary.select { |s| s[:late_count] > 0 }.map do |s|
        late_rate = ((s[:late_count].to_f / s[:days_worked]) * 100).round(0)
        s.merge(late_rate: late_rate)
      end.sort_by { |s| -s[:late_count] }.first(5)

      respond_to do |format|
        format.html
        format.csv { send_data generate_csv_report(@staff_summary), filename: "attendance_report_#{@start_date}_to_#{@end_date}.csv" }
      end
    end

    private

    # Helper to check if clock in time is after 9:15 AM
    def check_if_late(clock_in_time)
      return false if clock_in_time.blank?

      begin
        time = Time.parse(clock_in_time)

        # Create a cutoff time of 9:15 AM
        cutoff = Time.parse("9:15 AM")

        # Compare hour and minute
        if time.hour > cutoff.hour
          return true
        elsif time.hour == cutoff.hour && time.min > cutoff.min
          return true
        else
          return false
        end
      rescue => e
        Rails.logger.error "Error parsing clock_in_time '#{clock_in_time}': #{e.message}"
        false
      end
    end

    # Helper to check if clock out is before 6:00 PM
    def check_if_early_departure(clock_out_time)
      return false if clock_out_time.blank?

      begin
        time = Time.parse(clock_out_time)
        time.hour < 18
      rescue
        false
      end
    end

    # Parse time duration string to hours
    def calculate_hours_from_duration(duration_str)
      return 0 if duration_str.blank?

      begin
        parts = duration_str.gsub(/AM|PM/i, '').strip.split(':').map(&:to_i)
        hours = parts[0] || 0
        minutes = parts[1] || 0
        seconds = parts[2] || 0

        hours + (minutes / 60.0) + (seconds / 3600.0)
      rescue
        0
      end
    end

    def parse_date_from_excel(date_value)
      return nil if date_value.blank?

      # If it's already a Date object from Roo
      if date_value.is_a?(Date)
        return date_value
      end

      # If it's a DateTime object from Roo
      if date_value.is_a?(DateTime) || date_value.is_a?(Time)
        return date_value.to_date
      end

      # If it's a string, try parsing it
      if date_value.is_a?(String)
        # Handle format like "10/6/2025" (MM/DD/YYYY)
        if date_value.match?(/^\d{1,2}\/\d{1,2}\/\d{4}$/)
          parts = date_value.split('/')
          month = parts[0].to_i
          day = parts[1].to_i
          year = parts[2].to_i
          return Date.new(year, month, day)
        end

        # Try standard parsing
        begin
          return Date.parse(date_value)
        rescue
          return nil
        end
      end

      nil
    end

    def parse_time_from_excel(time_value)
      return nil if time_value.blank?

      # If it's already a Time/DateTime object from Roo, extract just the time part
      if time_value.is_a?(Time) || time_value.is_a?(DateTime)
        # Convert to local time zone first, then extract components
        local_time = time_value.in_time_zone('Africa/Lagos')
        hour = local_time.hour
        min = local_time.min
        sec = local_time.sec

        # Return as Time object in local zone to prevent further conversion
        return Time.zone.local(2000, 1, 1, hour, min, sec)
      end

      # If it's a string like "10:15:46 AM"
      if time_value.is_a?(String)
        begin
          parsed = Time.zone.parse(time_value)
          return Time.zone.local(2000, 1, 1, parsed.hour, parsed.min, parsed.sec)
        rescue
          return nil
        end
      end

      nil
    end

    def format_time_string(time_value)
      return nil if time_value.blank?

      # If it's a Time/DateTime object, extract components without timezone conversion
      if time_value.is_a?(Time) || time_value.is_a?(DateTime)
        # Get the raw hour/minute/second from the Excel DateTime object
        # Use utc to avoid timezone shifts, then format
        hour = time_value.hour
        min = time_value.min
        sec = time_value.sec

        # Determine AM/PM
        period = hour >= 12 ? 'PM' : 'AM'
        display_hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)

        return sprintf('%02d:%02d:%02d %s', display_hour, min, sec, period)
      end

      # If it's already a string, return as is
      if time_value.is_a?(String)
        return time_value.to_s
      end

      nil
    end

    def generate_csv(records)
      require 'csv'

      CSV.generate(headers: true) do |csv|
        csv << ['Staff Name', 'Date', 'Clock In', 'Clock Out', 'Work Time', 'Total OT', 'Location']

        records.each do |record|
          csv << [
            record.staff_name,
            record.attendance_date,
            record.clock_in,
            record.clock_out,
            record.work_time,
            record.total_ot,
            record.studio_location
          ]
        end
      end
    end

    def generate_csv_report(staff_summary)
      require 'csv'

      CSV.generate(headers: true) do |csv|
        csv << ['Staff Name', 'Days Worked', 'Avg Hours/Day', 'Late Arrivals', 'Early Departures', 'Location']

        staff_summary.each do |summary|
          csv << [
            summary[:name],
            summary[:days_worked],
            summary[:avg_hours],
            summary[:late_count],
            summary[:early_departures],
            summary[:location]
          ]
        end
      end
    end
  end
