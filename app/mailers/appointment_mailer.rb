class AppointmentMailer < ApplicationMailer
  default from: '363 Photography'

  def appointment_created(appointment)
    @appointment = appointment
    @location = studio_address
    @studio_phone_number = studio_number

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = @appointment.start_time.utc
      e.summary     = "Your Appointment at 363 Photography"
      e.description = "We look forward to seeing you!"
      e.location    = "Your Studio Address"
    end
    cal.publish

    attachments['appointment.ics'] = {
      mime_type: 'text/calendar',
      content: cal.to_ical
    }

    mail_from_studio(
      {
        to: @appointment.email,
        subject: '363 Photography Booking Confirmation'
      },
      @appointment.location
    )
  end

  def appointment_edited(appointment)
    @appointment = appointment
    mail_from_studio(
      {
        to: @appointment.email,
        subject: '363 Photography Booking Update'
      },
      @appointment.location
    )
  end

  def appointment_canceled(appointment)
    @appointment = appointment
    mail_from_studio(
      {
        to: @appointment.email,
        subject: '363 Photography Booking Cancellation'
      },
      @appointment.location
    )
  end

  def reminder_email(appointment)
    @appointment = appointment
    mail_from_studio(
      {
        to: @appointment.email,
        subject: 'Your Upcoming Appointment Reminder'
      },
      @appointment.location
    )
  end

  def policy_email(appointment)
    @appointment = appointment
    mail_from_studio(
      {
        to: @appointment.email,
        subject: "363 Photography Studio Policy"
      },
      @appointment.location
    )
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
