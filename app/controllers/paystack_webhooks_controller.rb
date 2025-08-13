class PaystackWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  include PaymentProcessor
  include PhoneNumberNormalizer


  def paystack
    # Verify that the request is from Paystack
    payload = request.raw_post
    signature = request.headers['x-paystack-signature']

    unless valid_signature?(signature, payload)
      Rails.logger.error("Invalid Paystack webhook signature")
      render json: { error: 'Invalid signature' }, status: :forbidden
      return
    end

    begin
      # Parse the JSON payload
      event = JSON.parse(payload)
      Rails.logger.info("Received Paystack webhook: #{event['event']}")
      handle_event(event)
      render json: { status: 'success' }, status: :ok
    rescue JSON::ParserError => e
      Rails.logger.error("JSON parsing error: #{e.message}")
      render json: { error: 'Invalid payload' }, status: :bad_request
    rescue => e
      Rails.logger.error("Error processing webhook: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: 'Internal error' }, status: :internal_server_error
    end
  end

  private

  def valid_signature?(signature, payload)
    return false if signature.blank? || payload.blank?

    secret = ENV['PAYSTACK_SECRET_KEY']
    expected_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret, payload)

    # Use secure comparison to prevent timing attacks
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end

  def handle_event(event)
    case event['event']
    when 'charge.success'
      # Mark payment as successful
      process_successful_charge(event['data'])
    when 'transfer.success'
      # Handle transfer success
    else
      Rails.logger.info("Unhandled event type: #{event['event']}")
    end
  end

  def process_successful_charge(data)
    # Find the relevant appointment using metadata
    appointment_uuid = data.dig('metadata', 'appointment_uuid')
    return unless appointment_uuid.present?

    appointment = Appointment.find_by(uuid: appointment_uuid)
    return unless appointment.present?

    # Don't double-process payments
    return if appointment.payment_status?

    # Update appointment payment status
    appointment.update(payment_status: true)

    # Create or update customer record
    customer = create_or_update_customer(appointment)

    # Create sale record
    create_sale(appointment, customer, data['metadata'])

    if appointment.referral_source.present?
      process_referral_conversion(appointment, customer)
    end

    begin
      AppointmentMailer.payment_confirmation(appointment, data).deliver_now
      Rails.logger.info("Payment confirmation email sent for appointment #{appointment.id}")
    rescue => e
      Rails.logger.error("Failed to send payment confirmation email: #{e.message}")
      # Don't fail the webhook if email sending fails
    end
    
    Rails.logger.info("Successfully processed payment for appointment #{appointment.id}")
  end
end
