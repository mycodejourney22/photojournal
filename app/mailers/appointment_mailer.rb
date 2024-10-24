class AppointmentMailer < ApplicationMailer
  default from: 'info@363photography.org'

  def appointment_created(appointment)
    @appointment = appointment
    mail(to: @appointment.email, subject: '363 Photography Booking Confirmation')
  end

  def appointment_edited(appointment)
    @appointment = appointment
    mail(to: @appointment.email, subject: '363 Photography Booking Update')
  end

  def appointment_canceled(appointment)
    @appointment = appointment
    mail(to: @appointment.email, subject: '363 Photography Booking Cancellation')
  end
end
