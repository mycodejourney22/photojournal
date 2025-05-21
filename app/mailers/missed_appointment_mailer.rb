class MissedAppointmentMailer < ApplicationMailer
    default from: '363 Photography <noreply@363photography.org>'
  
    def missed_appointment_email(appointment, attempt_number = 1)
      @appointment = appointment
      @attempt_number = attempt_number
      @reschedule_url = booking_appointments_url(id: @appointment.id)
      
      # Different subject lines based on attempt number
      subject_line = case attempt_number
        when 1
          "We missed you at 363 Photography today"
        when 2
          "Follow up: Your missed photoshoot with 363 Photography"
        else
          "Let's reschedule your 363 Photography session"
        end
  
        mail_from_studio(
        to: @appointment.email,
        subject: subject_line
      )
    end
end