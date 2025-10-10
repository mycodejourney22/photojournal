# app/models/attendance_record.rb
class AttendanceRecord < ApplicationRecord
    belongs_to :user # who uploaded the record
  
    validates :staff_name, presence: true
    validates :attendance_date, presence: true
    validates :ac_no, uniqueness: { scope: :attendance_date, message: "already has attendance for this date" }
  
    STUDIO_LOCATIONS = %w[ikeja surulere ajah].freeze
    validates :studio_location, inclusion: { in: STUDIO_LOCATIONS }, allow_nil: true
  
    scope :by_staff, ->(name) { where("LOWER(staff_name) = ?", name.downcase) if name.present? }
    scope :by_date_range, ->(start_date, end_date) { where(attendance_date: start_date..end_date) if start_date && end_date }
    scope :by_location, ->(location) { where(studio_location: location) if location.present? }
    scope :by_studio_id, ->(studio_id) { 
      return all unless studio_id.present?
      studio = Studio.find_by(id: studio_id)
      return none unless studio
      where(studio_location: studio.location.downcase)
    }
    scope :by_month, ->(month, year) { where("EXTRACT(MONTH FROM attendance_date) = ? AND EXTRACT(YEAR FROM attendance_date) = ?", month, year) }
    scope :recent, -> { order(attendance_date: :desc, created_at: :desc) }
  
    # Parse time duration strings like "8:16:57 AM" to decimal hours
    def work_hours
      parse_time_to_hours(work_time)
    end
  
    def overtime_hours
      parse_time_to_hours(total_ot)
    end
  
    private
  
    def parse_time_to_hours(time_str)
      return 0 unless time_str.present?
      
      # Handle formats like "8:16:57 AM" or just "8:16:57"
      time_str = time_str.gsub(/AM|PM/i, '').strip
      parts = time_str.split(':').map(&:to_i)
      
      return 0 if parts.empty?
      
      hours = parts[0] || 0
      minutes = parts[1] || 0
      seconds = parts[2] || 0
      
      hours + (minutes / 60.0) + (seconds / 3600.0)
    end
  end