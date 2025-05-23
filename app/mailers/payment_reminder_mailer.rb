class PaymentReminderMailer < ApplicationMailer
    default from: '363 Photography <noreply@363photography.org>'
  
    def payment_reminder_email(appointment, attempt_number = 1)
      @appointment = appointment
      @attempt_number = attempt_number
      @payment_url = make_payment_url(appointment_id: @appointment.id)
      
      # Different subject lines based on urgency
      subject_line = if @appointment.start_time < 24.hours.from_now
        "URGENT: Complete Your 363 Photography Booking Payment"
      elsif attempt_number > 3
        "Final Reminder: Your 363 Photography Appointment Needs Payment"
      else
        "Reminder: Complete Your 363 Photography Booking Payment"
      end

      mail_from_studio(
        to: @appointment.email,
        subject: subject_line
      )
    end
  
    def payment_final_reminder_email(appointment)
      @appointment = appointment
      @payment_url = make_payment_url(appointment_id: @appointment.id)
      @hours_remaining = ((appointment.start_time - Time.current) / 1.hour).round
      
      mail_from_studio(
        to: @appointment.email,
        subject: "URGENT: Last Chance to Complete Your 363 Photography Booking Payment"
      )
    end
  end