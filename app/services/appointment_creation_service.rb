# require 'pry'
class AppointmentCreationService
  def initialize(params, current_user = nil, session = nil)
    @params = params
    @current_user = current_user
    @session = session || {}
  end

  def call
    appointment = Appointment.new(@params)
    appointment.set_defaults(@current_user)
    appointment.uuid = SecureRandom.uuid

    # Apply referral from session if present
    if @session.present? && @session[:referral_code].present?
      appointment.referral_source = @session[:referral_code]
    end

    if appointment.save
      schedule_notifications(appointment)
      process_referral(appointment) if appointment.referral_source.present?
      schedule_payment_reminder(appointment) if requires_payment?(appointment)
      return { success: true, appointment: appointment }
    else
      return { success: false, appointment: appointment }
    end
  end

  private

  def schedule_notifications(appointment)
    appointment.schedule_policy_email
    appointment.schedule_reminder_email
    AppointmentNotificationJob.perform_later(appointment, 'created')

    appointment.schedule_sms_notifications

  end

  def process_referral(appointment)
    # Skip if no referral source
    # binding.pry
    referral_code = appointment.referral_source

    return unless referral_code.present?

    # Find an active referral with this code
    active_referral = Referral.where(code: referral_code, status: Referral::ACTIVE).first
    if active_referral.nil?
      Rails.logger.info("No active referral found with code: #{referral_code}")
      return
    end
    # Prevent self-referrals
    if active_referral.referrer.email == appointment.email
      appointment.update(referral_source: nil) # Clear invalid referral
      return
    end

    # Create or update the customer
    phone_number = extract_phone_number_from_appointment(appointment)
    normalized_phone = normalize_phone_number(phone_number)

    # First look for existing customer by phone number
    customer = Customer.find_by(phone_number: normalized_phone)

    # If not found by phone, try email
    if customer.nil? && appointment.email.present?
      customer = Customer.find_by(email: appointment.email)
    end

    # If still not found, create a new customer
    if customer.nil?
      customer = Customer.new(
        name: appointment.name,
        email: appointment.email,
        phone_number: normalized_phone
      )
      customer.save
    end

    # Check if this customer is eligible for a referral (new customer)
    unless Referral.customer_eligible_for_referral?(customer)
      # If not eligible, clear the referral source and return
      appointment.update(referral_source: nil)
      return
    end

    # Create a new conversion record for this specific referred customer
    conversion = Referral.create_conversion(referral_code, customer)

    # If conversion failed (e.g., not eligible), clear the referral source
    if conversion.nil?
      appointment.update(referral_source: nil)
    end

  end

  def requires_payment?(appointment)
    # Check if this appointment requires payment
    appointment.price_id.present? && !appointment.payment_status
  end

  def schedule_payment_reminder(appointment)
    # Schedule first payment reminder to be sent 20 minutes after booking
    UnpaidBookingReminderJob.set(wait: 2.minutes).perform_later(appointment.id)
  end

  def extract_phone_number_from_appointment(appointment)
    appointment.questions.find { |q| q.question == 'Phone number' }&.answer
  end

  def normalize_phone_number(phone_number)
    return nil unless phone_number

    # Remove non-numeric characters
    digits_only = phone_number.gsub(/\D/, '')

    # Check if phone number starts with the country code +234 or 234
    if digits_only.start_with?("234")
      # Replace '234' with '0'
      return digits_only.sub("234", "0")
    elsif digits_only.start_with?("+234")
      # Remove the '+' and replace '234' with '0'
      return digits_only.sub("+234", "0")
    end

    phone_number
  end
end
