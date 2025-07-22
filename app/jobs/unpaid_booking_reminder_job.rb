class UnpaidBookingReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id, attempt_number = 1)
    appointment = Appointment.find_by(id: appointment_id)
    
    # Abort if appointment doesn't exist or is already paid
    return if appointment.nil? || appointment.sales.exists? || appointment.channel != 'online'
    
    # Abort if the appointment date has passed
    return if Time.current > appointment.start_time
    
    # Send the appropriate reminder email
    if appointment.start_time < 12.hours.from_now
      # For appointments less than 12 hours away, send final reminder
      PaymentReminderMailer.payment_final_reminder_email(appointment).deliver_now
    else
      # Otherwise send regular reminder with attempt number
      PaymentReminderMailer.payment_reminder_email(appointment, attempt_number).deliver_now
      
      # Schedule next reminder based on how far away the appointment is
      days_until_appointment = (appointment.start_time - Time.current) / 1.day
      
      if days_until_appointment > 3
        # For appointments more than 3 days away, remind daily
        wait_time = 1.day
      elsif days_until_appointment > 1
        # For appointments 1-3 days away, remind every 12 hours
        wait_time = 12.hours
      else
        # For appointments less than 1 day away, remind every 4 hours
        wait_time = 4.hours
      end
      
      # Schedule next reminder, increment attempt number
      UnpaidBookingReminderJob.set(wait: wait_time).perform_later(appointment_id, attempt_number + 1)
    end
  end
end
