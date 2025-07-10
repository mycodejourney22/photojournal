# app/services/sms_service.rb
require 'net/http'
require 'uri'
require 'json'

class SmsService
  BASE_URL = "https://api.ebulksms.com"

  def initialize(username: nil, api_key: nil)
    @username = username || ENV['EBULK_SMS_USERNAME']
    @api_key = api_key || ENV['EBULK_SMS_API_KEY']
    @sender_name = ENV['EBULK_SMS_SENDER_NAME'] || '363Photo'
  end

  def send_thank_you_sms(photoshoot)
    # Extract phone number from appointment
    appointment = photoshoot.appointment
    phone_number = extract_phone_number(appointment)

    return false unless phone_number.present?

    message = build_thank_you_message(photoshoot)
    send_sms(phone_number, message)
  end



  def send_sms(phone_number, message)
    # Format the phone number to international format if needed
    formatted_number = format_phone_number(phone_number)

    # Prepare request data
    request_data = {
      SMS: {
        auth: {
          username: @username,
          apikey: @api_key
        },
        message: {
          sender: @sender_name,
          messagetext: message,
          flash: "0"
        },
        recipients: {
          gsm: [
            {
              msidn: formatted_number,
              msgid: generate_unique_id
            }
          ]
        },
        dndsender: 1
      }
    }

    # Make the API request
    uri = URI.parse("#{BASE_URL}/sendsms.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = request_data.to_json

    begin
      response = http.request(request)
      parsed_response = JSON.parse(response.body)

      Rails.logger.info("SMS response: #{parsed_response}")

      if response.code == "200" && parsed_response["response"]["status"] == "SUCCESS"
        return true
      else
        Rails.logger.error("Failed to send SMS: #{parsed_response["response"]["status"]}")
        return false
      end
    rescue => e
      Rails.logger.error("SMS sending error: #{e.message}")
      return false
    end
  end

  def send_appointment_confirmation_sms(appointment)
    phone_number = extract_phone_number(appointment)
    return false unless phone_number.present?

    message = build_appointment_confirmation_message(appointment)
    send_sms(phone_number, message)
  end

  def send_appointment_reminder_sms(appointment, reminder_type = '24_hours')
    phone_number = extract_phone_number(appointment)
    return false unless phone_number.present?

    message = build_appointment_reminder_message(appointment, reminder_type)
    send_sms(phone_number, message)
  end

  def send_appointment_update_sms(appointment)
    phone_number = extract_phone_number(appointment)
    return false unless phone_number.present?

    message = build_appointment_update_message(appointment)
    send_sms(phone_number, message)
  end

  def send_appointment_cancellation_sms(appointment)
    phone_number = extract_phone_number(appointment)
    return false unless phone_number.present?

    message = build_appointment_cancellation_message(appointment)
    send_sms(phone_number, message)
  end

  private

  def extract_phone_number(appointment)
    phone_question = appointment.questions.find { |q| q.question == 'Phone number' }
    return phone_question&.answer
  end

  def format_phone_number(phone_number)
    # Ensure the number is in the format required by the API (e.g., 234...)
    # First, remove any non-digit characters
    digits_only = phone_number.gsub(/\D/, '')

    # If it starts with 0, replace with country code
    if digits_only.start_with?('0')
      return "234" + digits_only[1..-1]
    elsif digits_only.start_with?('+234')
      return digits_only[1..-1] # Remove the plus
    elsif digits_only.start_with?('234')
      return digits_only
    else
      # Assume it's a Nigerian number and add the country code
      return "234" + digits_only
    end
  end

  def generate_unique_id
    "363photo_#{SecureRandom.hex(8)}"
  end

  def build_appointment_update_message(appointment)
    customer_name = appointment.name.split.first
    appointment_date = appointment.formatted_start_time
    appointment_time = appointment.formatted_time
    studio_phone = appointment.studio_phone

    message = <<~SMS
      Hello #{customer_name},

      Your appointment has been updated:

      📅 New Date: #{appointment_date}
      ⏰ New Time: #{appointment_time}
      📍 Location: #{appointment.location}

      Please save these new details. Arrive 15 minutes early.

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end

  def build_appointment_cancellation_message(appointment)
    customer_name = appointment.name.split.first
    studio_phone = appointment.studio_phone

    message = <<~SMS
      Hello #{customer_name},

      Your photoshoot appointment scheduled for #{appointment.formatted_start_time} has been cancelled.

      If you need to reschedule or have questions, please contact us at #{studio_phone}.

      We apologize for any inconvenience.

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end

  def build_thank_you_message(photoshoot)
    appointment = photoshoot.appointment
    customer_name = appointment.name.split.first

    message = <<~SMS
      Hello #{customer_name},
      Thank you for choosing 363 Photography for your photo shoot.
      In order for us to improve our services, please complete our feedback form using the
      link below.
      #{ENV['FEEDBACK_FORM_URL']}
      If you have any questions, please contact us at #{Appointment::STUDIO_NUMBERS[appointment.location.downcase] || '08144985074'}.

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end

  def send_referral_invitation_sms(referral)
    customer = referral.referrer
    phone_number = customer.phone_number

    return false unless phone_number.present?

    message = build_referral_invitation_message(referral)
    send_sms(phone_number, message)
  end

  def build_referral_invitation_message(referral)
    customer_name = referral.referrer.name.split.first
    referral_code = referral.code
    base_url = ENV['BASE_URL'] || 'https://363photography.org'

    message = <<~SMS
      Hello #{customer_name},

      Thanks for choosing 363 Photography! Share the love - when friends book a photoshoot with your referral code, you'll get ₦10,000 credit!

      Your referral code: #{referral_code}

      Share this link: #{base_url}/refer/#{referral_code}

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end

  def build_appointment_confirmation_message(appointment)
    customer_name = appointment.name.split.first
    appointment_date = appointment.formatted_start_time
    appointment_time = appointment.formatted_time
    studio_phone = appointment.studio_phone
    
    # Check if payment is required
    payment_text = if appointment.price_id.present? && !appointment.payment_status
      "\n\nIMPORTANT: Please complete your payment to secure your booking. Visit our website or call us."
    else
      ""
    end

    message = <<~SMS
      Hello #{customer_name},

      Your photoshoot appointment has been confirmed!

      📅 Date: #{appointment_date}
      ⏰ Time: #{appointment_time}
      📍 Location: #{appointment.location}#{payment_text}

      Studio Guidelines:
      • Arrive 15 mins early
      • If you are doing makeup in the studio arrive 1hr earlier

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end

  def build_appointment_reminder_message(appointment, reminder_type)
    customer_name = appointment.name.split.first
    appointment_date = appointment.formatted_start_time
    appointment_time = appointment.formatted_time
    studio_phone = appointment.studio_phone
    
    reminder_text = case reminder_type
    when '24_hours'
      "⏰ REMINDER: Your photoshoot is tomorrow!"
    when '2_hours'
      "🚨 FINAL REMINDER: Your photoshoot is in 2 hours!"
    else
      "📅 REMINDER: You have an upcoming photoshoot!"
    end

    # Check if payment is still required
    payment_text = if appointment.price_id.present? && !appointment.payment_status
      "\n\n⚠️ URGENT: Payment required to proceed with your appointment."
    else
      ""
    end

    message = <<~SMS
      Hello #{customer_name},

      #{reminder_text}

      📅 Date: #{appointment_date}
      ⏰ Time: #{appointment_time}
      📍 Location: #{appointment.location}#{payment_text}

      Please arrive 15 minutes early. Need to reschedule? Call us at least 24 hours before.

      363 Photography Team
    SMS

    # Ensure message is not too long (max 612 characters for SMS API)
    message.gsub(/\s+/, ' ').strip[0...612]
  end
end
