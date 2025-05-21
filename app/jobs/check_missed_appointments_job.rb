class CheckMissedAppointmentsJob < ApplicationJob
  queue_as :default

  def perform
    # Find appointments from yesterday that have no associated photoshoot
    yesterday = Time.zone.yesterday
    missed_appointments = Appointment.where(
      start_time: yesterday.beginning_of_day..yesterday.end_of_day,
      status: true, # Active appointments
      payment_status: true # Only consider paid appointments as missed
    ).select { |appointment| appointment.photo_shoot.nil? }
    
    # Schedule follow-up emails for each missed appointment
    missed_appointments.each do |appointment|
      MissedAppointmentFollowupJob.perform_later(appointment.id)
    end
    
    # Log the number of missed appointments processed
    Rails.logger.info "CheckMissedAppointmentsJob: Scheduled follow-ups for #{missed_appointments.size} missed appointments"
  end
end