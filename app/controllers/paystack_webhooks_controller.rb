class PaystackWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token # Webhooks are external requests

  def paystack
    # Verify that the request is from Paystack
    paystack_signature = request.headers['x-paystack-signature']
    raw_body = request.raw_post

    if valid_signature?(paystack_signature, raw_body)
      event = JSON.parse(raw_body)
      handle_event(event) # Your logic here
      render json: { status: 'success' }, status: :ok
    else
      render json: { error: 'Invalid signature' }, status: :forbidden
    end
  end

  private

  def valid_signature?(paystack_signature, raw_body)
    secret = ENV['PAYSTACK_SECRET_KEY']
    generated_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret, raw_body)
    ActiveSupport::SecurityUtils.secure_compare(generated_signature, paystack_signature)
  end

  def handle_event(event)
    case event['event']
    when 'charge.success'
      # Mark payment as successful
    when 'transfer.success'
      # Handle transfer success
    else
      # Handle other events
    end
  end
end
