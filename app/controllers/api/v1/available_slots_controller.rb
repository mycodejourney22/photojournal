# app/controllers/api/v1/available_slots_controller.rb
module Api
  module V1
    class AvailableSlotsController < Api::BaseController
      def index
        date = params[:date]
        location = params[:location]

        return render json: { error: 'Date and location are required' }, status: :bad_request unless date.present? && location.present?

        available_slots = generate_available_slots(date, location)
        render json: { date: date, location: location, available_slots: available_slots }
      end

      private

      def generate_available_slots(date, location)
        utc_date = Time.zone.parse(date)
        date_obj = utc_date.in_time_zone(Time.zone)

        # Get booked slots
        booked_slots = Appointment.where(
          location: location,
          status: true,
          start_time: date_obj.beginning_of_day..date_obj.end_of_day
        ).pluck(:start_time)

        # Generate all time slots
        all_slots = generate_time_slots(date_obj)

        # Filter out booked and past slots
        available_slots = all_slots.reject do |slot|
          booked_slots.include?(slot) || (date_obj.to_date == Time.zone.today && slot < Time.zone.now)
        end

        # Format the time slots
        available_slots.map do |slot|
          {
            time: slot.strftime("%H:%M"),
            formatted_time: format_time(slot)
          }
        end
      end

      def generate_time_slots(date)
        # Adjust start time based on day of week
        if date.sunday?
          start_time = Time.zone.parse("#{date.to_date} 12:30")
        else
          start_time = Time.zone.parse("#{date.to_date} 09:30")
        end

        end_time = Time.zone.parse("#{date.to_date} 16:30")
        (start_time.to_i..end_time.to_i).step(1.hour).map { |time| Time.zone.at(time) }
      end

      def format_time(time)
        hours = time.hour
        minutes = time.min
        formatted_time = "#{hours % 12 == 0 ? 12 : hours % 12}:#{minutes.to_s.rjust(2, '0')} #{hours < 12 ? 'AM' : 'PM'}"
        formatted_time
      end
    end
  end
end
