class AppointmentMailer < ApplicationMailer
  default from: '363 Photography'

  def appointment_created(appointment)
    @appointment = appointment
    @location = studio_address
    @studio_phone_number = studio_number
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

  def reminder_email(appointment)
    @appointment = appointment
    mail(to: @appointment.email, subject: 'Your Upcoming Appointment Reminder')
  end

  private

  def studio_address
    if @appointment.location.downcase == "ajah"
      "We are located beside NNPC filling station, Ilaje bus stop ajah "
    elsif @appointment.location.downcase == "surulere"
      "115A Bode Thomas Street, Surulere, Lagos"
    elsif @appointment.location.downcase == "ikeja"
      "66 Adeniyi Jones, Ikeja, Lagos"
    end
  end

  def studio_number
    if @appointment.location.downcase == "ajah"
      "08144985074"
    elsif @appointment.location.downcase == "surulere"
      "07048891715"
    elsif @appointment.location.downcase == "ikeja"
      "08090151168"
    end
  end
end
