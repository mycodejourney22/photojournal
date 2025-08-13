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

  def payment_confirmation(appointment, payment_data)
    @appointment = appointment
    @payment_data = payment_data
    @location = studio_address
    @studio_phone_number = studio_number
    
    # Extract payment information
    @amount_paid = @payment_data['amount'] / 100.0 # Convert from kobo to naira
    @reference = @payment_data['reference']
    @payment_date = Time.parse(@payment_data['paid_at']).strftime("%B %d, %Y at %I:%M %p")
    @original_amount = @payment_data.dig('metadata', 'original_amount') || @amount_paid
    @discount_amount = @payment_data.dig('metadata', 'discount_amount') || 0
    @referral_code = @payment_data.dig('metadata', 'referral_code')
  
    # Generate Google Calendar link
    @calendar_link = generate_calendar_link(@appointment)
  
    mail_from_studio(
      {
        to: @appointment.email,
        subject: 'Payment Confirmed - Your 363 Photography Session is Ready!'
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

  def generate_calendar_link(appointment)
    base_url = "https://www.google.com/calendar/render?action=TEMPLATE"
    event_title = CGI.escape('Your Photoshoot at 363 Photography')
    start_time = appointment.start_time.utc.strftime('%Y%m%dT%H%M%SZ')
    end_time = (appointment.start_time + 2.hours).utc.strftime('%Y%m%dT%H%M%SZ')
    details = CGI.escape('We look forward to your session. Please arrive 15 minutes early.')
    location = CGI.escape(studio_address)
  
    "#{base_url}&text=#{event_title}&dates=#{start_time}/#{end_time}&details=#{details}&location=#{location}"
  end
end
