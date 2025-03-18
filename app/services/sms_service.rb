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
end
