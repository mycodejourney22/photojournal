class MissedAppointmentFollowupJob < ApplicationJob
  queue_as :default

  def perform(appointment_id, attempt_number = 1)
    appointment = Appointment.find_by(id: appointment_id)
    
    # Abort if appointment doesn't exist or if a photoshoot was created
    return if appointment.nil? || appointment.photo_shoot.present?
    
    # Abort if we've already tried the maximum number of attempts
    return if attempt_number > 3
    
    # Send missed appointment email
    MissedAppointmentMailer.missed_appointment_email(appointment, attempt_number).deliver_now
    
    # Schedule next follow-up email in 2 days if not the final attempt
    if attempt_number < 3
      MissedAppointmentFollowupJob.set(wait: 2.days).perform_later(appointment_id, attempt_number + 1)
    end
  end
end