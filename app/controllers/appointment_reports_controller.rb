# app/controllers/appointment_reports_controller.rb
class AppointmentReportsController < ApplicationController
  before_action :set_date_range
  before_action :set_location_filter

  def index
    authorize :appointment_report, :index?
    
    # Get base appointments and photoshoots based on filters
    @appointments = filter_by_location(Appointment.all)
    @photoshoots = filter_by_location_photoshoots(PhotoShoot.all)

    # Calculate metrics
    @appointments_created = calculate_appointments_created
    @photoshoots_completed = calculate_photoshoots_completed
    @missed_sessions = calculate_missed_sessions
    @online_bookings = calculate_online_bookings  # NEW METRIC
    
    # Chart data for daily trends
    @appointments_chart_data = appointments_chart_data
    @photoshoots_chart_data = photoshoots_chart_data
    @missed_sessions_chart_data = missed_sessions_chart_data
    @online_bookings_chart_data = online_bookings_chart_data
    
    # Location breakdown
    @location_breakdown = location_breakdown

    # Shoot type analytics
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

  def filter_by_location(scope)
    return scope unless @selected_location
    
    case scope.table_name
    when 'appointments'
      scope.where(location: @selected_location)
    else
      scope
    end
  end

  def filter_by_location_photoshoots(scope)
    return scope unless @selected_location
    
    scope.joins(:appointment).where(appointments: { location: @selected_location })
  end

  def calculate_appointments_created
    @appointments.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
  end

  def calculate_photoshoots_completed
    @photoshoots.where(date: @start_date..@end_date).count
  end

  def calculate_online_bookings
    @appointments.where(
      created_at: @start_date.beginning_of_day..@end_date.end_of_day,
      channel: 'online'
    ).count
  end

  def calculate_missed_sessions
    # Find appointments that:
    # 1. Had a scheduled start_time before today
    # 2. Don't have an associated photoshoot
    # 3. Were active (status = true)
    # 4. Had payment completed or no payment required
    
    past_appointments = @appointments.where(
      start_time: @start_date.beginning_of_day..[@end_date.end_of_day, Time.current].min,
      status: true
    ).where('start_time < ?', Time.current)

    missed_count = 0
    past_appointments.find_each do |appointment|
      # Check if appointment doesn't have a photoshoot
      if appointment.photo_shoot.nil?
        # Only count as missed if payment was completed or no payment was required
        missed_count += 1
      end
    end

    missed_count
  end

  def shoot_type_breakdown
    # Use base appointments without additional location filtering since @appointments is already filtered
    appointments_scope = @selected_location ? 
      Appointment.where(location: @selected_location) : 
      Appointment.all
    
    photoshoots_scope = @selected_location ?
      PhotoShoot.joins(:appointment).where(appointments: { location: @selected_location }) :
      PhotoShoot.all

    # Get appointments with prices to analyze shoot types
    appointments_with_prices = appointments_scope
      .joins(:price)
      .where(start_time: @start_date.beginning_of_day..@end_date.end_of_day)
      .group('prices.shoot_type')
      .count

    # Get completed photoshoots by shoot type
    completed_by_type = photoshoots_scope
      .joins(appointment: :price)
      .where(date: @start_date..@end_date)
      .group('prices.shoot_type')
      .count

    # Get missed sessions by shoot type
    missed_by_type = {}
    
    appointments_scope
      .joins(:price)
      .where(
        start_time: @start_date.beginning_of_day..[@end_date.end_of_day, Time.current].min,
        status: true
      )
      .where('start_time < ?', Time.current)
      .includes(:photo_shoot, :price)
      .find_each do |appointment|
        if appointment.photo_shoot.nil?
          shoot_type = appointment.price.shoot_type
          missed_by_type[shoot_type] ||= 0
          missed_by_type[shoot_type] += 1
        end
      end

    # Combine data
    all_shoot_types = (appointments_with_prices.keys + completed_by_type.keys + missed_by_type.keys).uniq

    result = all_shoot_types.map do |shoot_type|
      appointments_count = appointments_with_prices[shoot_type] || 0
      completed_count = completed_by_type[shoot_type] || 0
      missed_count = missed_by_type[shoot_type] || 0

      {
        shoot_type: shoot_type,
        appointments_created: appointments_count,
        photoshoots_completed: completed_count,
        missed_sessions: missed_count,
        conversion_rate: appointments_count > 0 ? ((completed_count.to_f / appointments_count) * 100).round(1) : 0
      }
    end.sort_by { |data| -data[:appointments_created] }

    Rails.logger.debug "Shoot type breakdown result: #{result.inspect}"
    result
  end

  def popular_shoot_types
    # Use base appointments without additional location filtering here since @appointments is already filtered
    appointments_scope = @selected_location ? 
      Appointment.where(location: @selected_location) : 
      Appointment.all
      
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

  def appointments_chart_data
    daily_data = {}
    
    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    appointments_by_day = @appointments
      .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
      .group('DATE(created_at)')
      .count

    appointments_by_day.each do |date_obj, count|
      # Handle both Date objects and date strings
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
      # Handle both Date objects and date strings
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

    online_bookings_by_day = @appointments
      .where(
        created_at: @start_date.beginning_of_day..@end_date.end_of_day,
        channel: 'online'
      )
      .group('DATE(created_at)')
      .count

    online_bookings_by_day.each do |date_obj, count|
      # Handle both Date objects and date strings
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
      
      day_appointments = @appointments.where(
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
      location_appointments = Appointment.where(location: location)
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

  def send_csv_export
    csv_data = generate_csv_data
    
    filename = "appointment_reports_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}"
    filename += "_#{@selected_location.downcase}" if @selected_location
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
      csv << ["Online Bookings", @online_bookings]
      csv << ["Total Photoshoots Completed", @photoshoots_completed]
      csv << ["Total Missed Sessions", @missed_sessions]
      csv << ["Conversion Rate", @appointments_created > 0 ? "#{((@photoshoots_completed.to_f / @appointments_created) * 100).round(1)}%" : "0%"]
      csv << ["Online Booking Rate", @appointments_created > 0 ? "#{((@online_bookings.to_f / @appointments_created) * 100).round(1)}%" : "0%"]
      csv << []

      # Location breakdown
      csv << ["Location Breakdown"]
      csv << ["Location", "Appointments Created", "Online Bookings", "Photoshoots Completed", "Missed Sessions", "Conversion Rate", "Online Booking Rate"]
      
      @location_breakdown.each do |location_data|
        csv << [
          location_data[:location],
          location_data[:appointments_created],
          location_data[:online_bookings],
          location_data[:photoshoots_completed],
          location_data[:missed_sessions],
          "#{location_data[:conversion_rate]}%",
          "#{location_data[:online_booking_rate]}%"
        ]
      end
      
      csv << []

      # Daily breakdown
      csv << ["Daily Breakdown"]
      csv << ["Date", "Appointments Created", "Online Bookings", "Photoshoots Completed", "Missed Sessions"]
      
      (@start_date..@end_date).each do |date|
        appointments_count = @appointments
          .where(created_at: date.beginning_of_day..date.end_of_day)
          .count

        online_bookings_count = @appointments
          .where(
            created_at: date.beginning_of_day..date.end_of_day,
            channel: 'online'
          )
          .count

        photoshoots_count = @photoshoots
          .where(date: date)
          .count

        # Calculate missed sessions for this specific date
        missed_count = 0
        if date < Date.today
          day_appointments = @appointments.where(
            start_time: date.beginning_of_day..date.end_of_day,
            status: true
          )

          day_appointments.find_each do |appointment|
            if appointment.photo_shoot.nil? 
              missed_count += 1
            end
          end
        end

        csv << [
          date.strftime('%B %d, %Y'),
          appointments_count,
          online_bookings_count,
          photoshoots_count,
          missed_count
        ]
      end
    end
  end
end