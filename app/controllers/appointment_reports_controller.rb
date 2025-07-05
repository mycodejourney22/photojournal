# app/controllers/appointment_reports_controller.rb
class AppointmentReportsController < ApplicationController
  before_action :set_date_range
  before_action :set_location_filter
  before_action :set_channel_filter  # NEW: Add channel filter

  def index
    authorize :appointment_report, :index?
    
    # Get base appointments and photoshoots based on filters
    @appointments = filter_by_location(Appointment.all)
    @photoshoots = filter_by_location_photoshoots(PhotoShoot.all)

    # Calculate metrics
    @appointments_created = calculate_appointments_created
    @appointments_by_date = calculate_appointments_by_date  # NEW METRIC
    @photoshoots_completed = calculate_photoshoots_completed
    @missed_sessions = calculate_missed_sessions
    @online_bookings = calculate_online_bookings
    
    # Chart data for daily trends
    @appointments_chart_data = appointments_chart_data
    @appointments_by_date_chart_data = appointments_by_date_chart_data  # NEW CHART DATA
    @photoshoots_chart_data = photoshoots_chart_data
    @missed_sessions_chart_data = missed_sessions_chart_data
    @online_bookings_chart_data = online_bookings_chart_data
    
    # Location breakdown
    @location_breakdown = location_breakdown

    # Shoot type analytics with enhanced filtering
    @shoot_type_breakdown = shoot_type_breakdown
    @popular_shoot_types = popular_shoot_types
    
    # Export functionality
    respond_to do |format|
      format.html
      format.csv { send_csv_export }
    end
  end

  private

  def set_date_range
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    
    # Ensure end_date is not in the future
    @end_date = [@end_date, Date.today].min
    
    # Ensure start_date is not after end_date
    @start_date = [@start_date, @end_date].min
  end

  def set_location_filter
    @selected_location = params[:location].present? && params[:location] != 'All Locations' ? params[:location] : nil
  end

  # NEW: Add channel filter for online/offline bookings
  def set_channel_filter
    @selected_channel = params[:channel].present? && params[:channel] != 'All Channels' ? params[:channel] : nil
  end

  def filter_by_location(scope)
    return scope unless @selected_location
    
    case scope.table_name
    when 'appointments'
      scope.where(location: @selected_location)
    else
      scope
    end
  end

  # NEW: Add channel filtering
  def filter_by_channel(scope)
    return scope unless @selected_channel
    scope.where(channel: @selected_channel)
  end

  # Apply all filters to appointments
  def filtered_appointments
    appointments = filter_by_location(Appointment.all)
    appointments = filter_by_channel(appointments)
    appointments
  end

  def filter_by_location_photoshoots(scope)
    return scope unless @selected_location
    
    scope.joins(:appointment).where(appointments: { location: @selected_location })
  end

  def calculate_appointments_created
    filtered_appointments.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
  end

  # NEW: Calculate appointments by actual appointment date (start_time)
  def calculate_appointments_by_date
    filtered_appointments.where(start_time: @start_date.beginning_of_day..@end_date.end_of_day).count
  end

  def calculate_photoshoots_completed
    @photoshoots.where(date: @start_date..@end_date).count
  end

  def calculate_online_bookings
    filtered_appointments.where(
      created_at: @start_date.beginning_of_day..@end_date.end_of_day,
      channel: 'online'
    ).count
  end

  def calculate_missed_sessions
    # Find appointments that:
    # 1. Had a scheduled start_time before today
    # 2. Don't have an associated photoshoot
    # 3. Were active (status = true)
    # 4. Fall within our date range
    past_appointments = filtered_appointments.where(
      start_time: @start_date.beginning_of_day..[@end_date.end_of_day, Time.current].min,
      status: true
    ).where('start_time < ?', Time.current)

    missed_count = 0
    past_appointments.find_each do |appointment|
      if appointment.photo_shoot.nil? 
        missed_count += 1
      end
    end

    missed_count
  end

  def appointments_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    appointments_by_day = filtered_appointments
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
      .group('DATE(created_at)')
      .count

    appointments_by_day.each do |date_obj, count|
      date = date_obj.is_a?(Date) ? date_obj : Date.parse(date_obj.to_s)
      if date >= @start_date && date <= @end_date
        daily_data[date.strftime("%b %d")] = count
      end
    end

    daily_data.map { |date, count| { date: date, count: count } }
  end

  # NEW: Chart data for appointments by actual appointment date
  def appointments_by_date_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    appointments_by_day = filtered_appointments
      .where(start_time: @start_date.beginning_of_day..@end_date.end_of_day)
      .group('DATE(start_time)')
      .count

    appointments_by_day.each do |date_obj, count|
      date = date_obj.is_a?(Date) ? date_obj : Date.parse(date_obj.to_s)
      if date >= @start_date && date <= @end_date
        daily_data[date.strftime("%b %d")] = count
      end
    end

    daily_data.map { |date, count| { date: date, count: count } }
  end

  def photoshoots_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    photoshoots_by_day = @photoshoots
      .where(date: @start_date..@end_date)
      .group(:date)
      .count

    photoshoots_by_day.each do |date_obj, count|
      date = date_obj.is_a?(Date) ? date_obj : Date.parse(date_obj.to_s)
      if date >= @start_date && date <= @end_date
        daily_data[date.strftime("%b %d")] = count
      end
    end

    daily_data.map { |date, count| { date: date, count: count } }
  end

  def online_bookings_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    online_bookings_by_day = filtered_appointments
      .where(
        created_at: @start_date.beginning_of_day..@end_date.end_of_day,
        channel: 'online'
      )
      .group('DATE(created_at)')
      .count

    online_bookings_by_day.each do |date_obj, count|
      date = date_obj.is_a?(Date) ? date_obj : Date.parse(date_obj.to_s)
      if date >= @start_date && date <= @end_date
        daily_data[date.strftime("%b %d")] = count
      end
    end

    daily_data.map { |date, count| { date: date, count: count } }
  end

  def missed_sessions_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    # Calculate missed sessions by day
    (@start_date..@end_date).each do |date|
      next if date >= Date.today # Can't have missed sessions for future dates
      
      day_appointments = filtered_appointments.where(
        start_time: date.beginning_of_day..date.end_of_day,
        status: true
      )

      missed_count = 0
      day_appointments.find_each do |appointment|
        if appointment.photo_shoot.nil? 
          missed_count += 1
        end
      end

      daily_data[date.strftime("%b %d")] = missed_count
    end

    daily_data.map { |date, count| { date: date, count: count } }
  end

  def location_breakdown
    locations = @selected_location ? [@selected_location] : ['Ajah', 'Ikeja', 'Surulere']
    
    locations.map do |location|
      # Apply channel filter along with location filter
      location_appointments = Appointment.where(location: location)
      location_appointments = filter_by_channel(location_appointments)
      
      location_photoshoots = PhotoShoot.joins(:appointment).where(appointments: { location: location })

      appointments_count = location_appointments
        .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
        .count

      online_bookings_count = location_appointments
        .where(
          created_at: @start_date.beginning_of_day..@end_date.end_of_day,
          channel: 'online'
        )
        .count

      photoshoots_count = location_photoshoots
        .where(date: @start_date..@end_date)
        .count

      # Calculate missed sessions for this location
      past_appointments = location_appointments.where(
        start_time: @start_date.beginning_of_day..[@end_date.end_of_day, Time.current].min,
        status: true
      ).where('start_time < ?', Time.current)

      missed_count = 0
      past_appointments.find_each do |appointment|
        if appointment.photo_shoot.nil? 
          missed_count += 1
        end
      end

      {
        location: location,
        appointments_created: appointments_count,
        online_bookings: online_bookings_count,
        photoshoots_completed: photoshoots_count,
        missed_sessions: missed_count,
        conversion_rate: appointments_count > 0 ? ((photoshoots_count.to_f / appointments_count) * 100).round(1) : 0,
        online_booking_rate: appointments_count > 0 ? ((online_bookings_count.to_f / appointments_count) * 100).round(1) : 0
      }
    end
  end

  # ENHANCED: Shoot type breakdown with channel filtering
  def shoot_type_breakdown
    # Use filtered appointments scope
    appointments_scope = filtered_appointments
      
    shoot_types = appointments_scope
      .joins(:price)
      .where(start_time: @start_date.beginning_of_day..@end_date.end_of_day)
      .distinct
      .pluck('prices.shoot_type')
      .compact

    result = shoot_types.map do |shoot_type|
      # Get appointments for this shoot type
      type_appointments = appointments_scope
        .joins(:price)
        .where(
          start_time: @start_date.beginning_of_day..@end_date.end_of_day,
          prices: { shoot_type: shoot_type }
        )

      appointments_count = type_appointments.count

      # Count online bookings for this shoot type
      online_bookings_count = type_appointments.where(channel: 'online').count

      # Count completed photoshoots for this shoot type
      completed_count = type_appointments
        .joins(:photo_shoot)
        .where(photo_shoots: { date: @start_date..@end_date })
        .count

      {
        shoot_type: shoot_type,
        appointments_created: appointments_count,
        online_bookings: online_bookings_count,
        photoshoots_completed: completed_count,
        online_booking_rate: appointments_count > 0 ? ((online_bookings_count.to_f / appointments_count) * 100).round(1) : 0,
        conversion_rate: appointments_count > 0 ? ((completed_count.to_f / appointments_count) * 100).round(1) : 0
      }
    end.sort_by { |data| -data[:appointments_created] }

    Rails.logger.debug "Shoot type breakdown result: #{result.inspect}"
    result
  end

  def popular_shoot_types
    # Use filtered appointments scope
    appointments_scope = filtered_appointments
      
    result = appointments_scope
      .joins(:price)
      .where(start_time: @start_date.beginning_of_day..@end_date.end_of_day)
      .group('prices.shoot_type')
      .count('appointments.id')
      .sort_by { |shoot_type, count| -count }
      .take(5)
      .to_h
    
    mapped_result = result.map { |shoot_type, count| { shoot_type: shoot_type, count: count } }
    
    # Debug logging
    Rails.logger.debug "Popular shoot types raw result: #{result.inspect}"
    Rails.logger.debug "Popular shoot types mapped result: #{mapped_result.inspect}"
    
    # Return empty array if no results
    mapped_result.present? ? mapped_result : []
  end

  def send_csv_export
    csv_data = generate_csv_data
    
    filename = "appointment_reports_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}"
    filename += "_#{@selected_location.downcase}" if @selected_location
    filename += "_#{@selected_channel.downcase}" if @selected_channel
    filename += ".csv"

    send_data csv_data, 
              type: 'text/csv', 
              filename: filename,
              disposition: 'attachment'
  end

  def generate_csv_data
    require 'csv'

    CSV.generate do |csv|
      # Header
      csv << [
        "363 Photography Appointment Reports",
        "Period: #{@start_date.strftime('%B %d, %Y')} - #{@end_date.strftime('%B %d, %Y')}"
      ]
      csv << []

      # Summary metrics
      csv << ["Summary Metrics"]
      csv << ["Total Appointments Created", @appointments_created]
      csv << ["Total Appointments by Date", @appointments_by_date]  # NEW
      csv << ["Online Bookings", @online_bookings]
      csv << ["Total Photoshoots Completed", @photoshoots_completed]
      csv << ["Total Missed Sessions", @missed_sessions]
      csv << ["Conversion Rate", @appointments_created > 0 ? "#{((@photoshoots_completed.to_f / @appointments_created) * 100).round(1)}%" : "0%"]
      csv << ["Online Booking Rate", @appointments_created > 0 ? "#{((@online_bookings.to_f / @appointments_created) * 100).round(1)}%" : "0%"]
      csv << []

      # Shoot type breakdown with online booking details
      csv << ["Shoot Type Breakdown"]
      csv << ["Shoot Type", "Appointments", "Online Bookings", "Completed", "Online Rate %", "Conversion Rate %"]
      @shoot_type_breakdown.each do |data|
        csv << [
          data[:shoot_type],
          data[:appointments_created],
          data[:online_bookings],
          data[:photoshoots_completed],
          data[:online_booking_rate],
          data[:conversion_rate]
        ]
      end
      csv << []

      # Location breakdown
      csv << ["Location Breakdown"]
      csv << ["Location", "Appointments", "Online Bookings", "Completed", "Missed", "Conversion Rate %", "Online Rate %"]
      @location_breakdown.each do |data|
        csv << [
          data[:location],
          data[:appointments_created],
          data[:online_bookings],
          data[:photoshoots_completed],
          data[:missed_sessions],
          data[:conversion_rate],
          data[:online_booking_rate]
        ]
      end
    end
  end
end