# class CheckMissedAppointmentsJob < ApplicationJob
#   queue_as :default
#   include Sidekiq::Worker


#   def perform
#     # Find appointments from yesterday that have no associated photoshoot
#     yesterday = Time.zone.yesterday
#     missed_appointments = Appointment.where(
#       start_time: yesterday.beginning_of_day..yesterday.end_of_day,
#       status: true, # Active appointments
#       payment_status: true # Only consider paid appointments as missed
#     ).select { |appointment| appointment.photo_shoot.nil? }
    
#     # Schedule follow-up emails for each missed appointment
#     missed_appointments.each do |appointment|
#       MissedAppointmentFollowupJob.perform_later(appointment.id)
#     end
    
#     # Log the number of missed appointments processed
#     Rails.logger.info "CheckMissedAppointmentsJob: Scheduled follow-ups for #{missed_appointments.size} missed appointments"
#   end
# end

class CheckMissedAppointmentsJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    yesterday = Time.zone.yesterday
    missed_appointments = Appointment.where(
      start_time: yesterday.beginning_of_day..yesterday.end_of_day,
      status: true
    ).select { |appointment| appointment.photo_shoot.nil? }

    missed_appointments.each do |appointment|
      MissedAppointmentFollowupJob.perform_async(appointment.id) # Use Sidekiq here too
    end

    Rails.logger.info "CheckMissedAppointmentsJob: Scheduled follow-ups for #{missed_appointments.size} missed appointments"
  end
end
