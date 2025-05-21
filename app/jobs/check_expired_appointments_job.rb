class CheckExpiredAppointmentsJob < ApplicationJob
  queue_as :default

  def perform
    # Find appointments that:
    # 1. Are scheduled within the next 12 hours
    # 2. Require payment (have a price_id)
    # 3. Payment has not been made (payment_status = false)
    # 4. Are still marked as active (status = true)
    soon_unpaid_appointments = Appointment.where(
      start_time: Time.zone.now..(Time.zone.now + 12.hours),
      payment_status: false,
      status: true
    ).where.not(price_id: nil)
    
    # Send final payment reminder to each appointment
    soon_unpaid_appointments.each do |appointment|
      # Skip if the appointment is less than 2 hours away - it's likely too late
      next if appointment.start_time < (Time.zone.now + 2.hours)
      
      # Send urgent final reminder
      PaymentReminderMailer.payment_final_reminder_email(appointment).deliver_later
      
      # If appointment is less than 6 hours away, schedule a job to cancel it automatically
      # if payment isn't received in the next 2 hours
      if appointment.start_time < (Time.zone.now + 6.hours)
        ExpireUnpaidAppointmentJob.set(wait: 2.hours).perform_later(appointment.id)
      end
    end
    
    # Log number of appointments processed
    Rails.logger.info "CheckExpiredAppointmentsJob: Found #{soon_unpaid_appointments.size} unpaid upcoming appointments"
  end
end