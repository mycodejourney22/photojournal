class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!
  require 'net/http'
  require 'uri'
  require 'json'
  layout 'public'
  layout :determine_layout
  include PaymentProcessor
  include PhoneNumberNormalizer

  # def make_payment
  #   @appointment = Appointment.find(params[:appointment_id])
  #   @price = Price.find(@appointment.price_id)
  # end

  def make_payment
    @appointment = Appointment.find(params[:appointment_id])
    @price = Price.find(@appointment.price_id)

    # Identify customer by phone number from the appointment
    phone_number = extract_phone_number_from_appointment(@appointment)
    @customer = Customer.find_by(phone_number: phone_number)

    # Check if customer has credits
    @available_credits = @customer&.credits.to_i

    # Handle credit application if requested
    if params[:apply_credits].present?
      # Calculate how many credits to apply (can't apply more than available or total price)
      requested_credits = params[:apply_credits].to_i
      @credits_applied = [requested_credits, @available_credits, @price.amount].min

      # Store in session for payment processing
      session[:customer_id_for_credits] = @customer.id
      session[:credits_to_apply] = @credits_applied
    elsif session[:credits_to_apply].present?
      # If returning to this page after previously selecting credits
      @credits_applied = session[:credits_to_apply].to_i
    else
      @credits_applied = 0
    end

    handle_coupon_application

    calculate_final_amount_with_all_discounts
    # Calculate final amount
    # @final_amount = @price.amount - @credits_applied
    # @final_amount = 0 if @final_amount < 0

    # # Calculate price with referral discount if applicable
    # if @appointment.referral_source.present?
    #   referral = Referral.find_by(code: @appointment.referral_source)
    #   @referral_discount = referral&.referred_discount || 5000
    #   @final_amount = @final_amount - @referral_discount
    #   @final_amount = 0 if @final_amount < 0
    # end
  end

  def initiate_payment
    appointment = Appointment.find(params[:appointment_id])
    price = Price.find(params[:price_id])
    email = appointment.email || "default@example.com"
    credits_applied = params[:credits_applied].to_i || 0


    if credits_applied > 0 && credits_applied >= price.amount
      process_credit_payment(appointment, credits_applied)
      return
    end

    # Calculate payment amount with discount if a referral was used
    amount = price.amount.to_f - credits_applied
    total_discount = 0

    if session[:coupon_discount].present? && session[:coupon_appointment_id] == appointment.id.to_s
      coupon_discount = session[:coupon_discount].to_i
      amount -= coupon_discount
      total_discount += coupon_discount
      
      # Store coupon info in appointment for tracking
      if session[:applied_coupon_code].present?
        appointment.update(
          coupon_code: session[:applied_coupon_code],
          coupon_discount: coupon_discount
        )
        
        # Increment coupon usage and clear session after successful application
        coupon = Coupon.find_by(code: session[:applied_coupon_code])
        coupon&.increment_usage!
        
        # Clear coupon session after successful payment initiation
        clear_coupon_session_for_payment
      end
    end

    if appointment.referral_source.present?
      referral = Referral.find_by(code: appointment.referral_source)
      referral_discount = referral&.referred_discount || 5000
      amount = [amount - referral_discount, 0].max # Make sure amount isn't negative
    end

    amount = [amount, 0].max

    if amount <= 0
      appointment.update(payment_status: true)
      process_credit_payment(appointment, credits_applied) if credits_applied > 0
      redirect_to success_payments_path(appointment_id: appointment.id)
      return
    end

    # Convert to kobo (smallest currency unit) for Paystack
    paystack_amount = (amount * 100).to_i

    uri = URI("https://api.paystack.co/transaction/initialize")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    request['Content-Type'] = 'application/json'
    request.body = {
      email: email,
      amount: paystack_amount,
      metadata: {
        appointment_uuid: appointment.uuid,
        original_amount: amount.to_f,# Store as float
        discount_amount: referral_discount.to_f,
        referral_code: appointment.referral_source
      }
    }.to_json

    begin
      response = http.request(request)

      if response.code == "200"
        parsed_response = JSON.parse(response.body)

        if parsed_response['status'] == true
          redirect_to parsed_response["data"]["authorization_url"], allow_other_host: true, status: :see_other
        else
          flash[:error] = parsed_response['message'] || "Payment initiation failed."
          redirect_to new_payment_path
        end
      else
        flash[:error] = "Failed to connect to Paystack. HTTP Status: #{response.code}"
        redirect_to new_payment_path
      end
    rescue Timeout::Error, SocketError => e
      flash[:error] = "Connection to Paystack failed. Please try again later."
      Rails.logger.error("Paystack Timeout/Socket Error: #{e.message}")
      redirect_to new_payment_path
    rescue JSON::ParserError => e
      flash[:error] = "Unexpected response from Paystack."
      Rails.logger.error("Paystack JSON Parsing Error: #{e.message}")
      redirect_to new_payment_path
    end
  end

  def verify_payment
    reference = params[:reference]
    begin
      uri = URI("https://api.paystack.co/transaction/verify/#{reference}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 15

      # Use GET request instead of POST
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
      request['Content-Type'] = "application/json"

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        response_body = JSON.parse(response.body)

        if response_body['status'] && response_body['data']['status'] == "success"
          # Handle successful payment
          appointment_uuid = response_body['data']['metadata']['appointment_uuid'] rescue nil

          if appointment_uuid.blank?
            Rails.logger.error("Transaction #{reference} has no appointment UUID in metadata")
            redirect_to failure_payments_path, alert: "Could not find booking information"
            return
          end

          # Find appointment
          appointment = Appointment.find_by(uuid: appointment_uuid)

          if appointment.nil?
            Rails.logger.error("Appointment with UUID #{appointment_uuid} not found")
            redirect_to failure_payments_path, alert: "Booking information not found"
            return
          end

          if appointment.payment_status
            Rails.logger.info("Payment for appointment #{appointment.id} already processed")
            redirect_to success_payments_path(appointment_id: appointment.id)
            return
          end

          # Process payment
          appointment.update(payment_status: true)


          # Create customer and sale
          customer = create_or_update_customer(appointment)

          # binding.pry
          # Process referral if present
          if appointment.referral_source.present?
            # Double-check customer is still eligible
            if Referral.customer_eligible_for_referral?(customer)
              process_referral_conversion(appointment, customer)
            else
              # If no longer eligible, clear the referral source
              appointment.update(referral_source: nil)
            end
          end

          create_sale(appointment, customer, response_body['data']['metadata'])


          # Clear the referral code from session since payment is confirmed
          session.delete(:referral_code)
          Rails.logger.info("Payment successfully verified and processed for appointment #{appointment.id}")
          redirect_to success_payments_path(appointment_id: appointment.id)
        else
          error_message = response_body['message'] || "Verification failed"
          Rails.logger.error("Payment verification failed: #{error_message}")
          redirect_to failure_payments_path, alert: "Payment verification failed."
        end
      else
        Rails.logger.error("Failed to verify payment: HTTP #{response.code}")
        redirect_to failure_payments_path, alert: "Failed to communicate with payment gateway."
      end
    rescue => e
      Rails.logger.error("Exception during payment verification: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      redirect_to failure_payments_path, alert: "An error occurred during payment verification. Please contact support."
    end
    begin
      AppointmentMailer.payment_confirmation(appointment, data).deliver_now
      Rails.logger.info("Payment confirmation email sent for appointment #{appointment.id}")
    rescue => e
      Rails.logger.error("Failed to send payment confirmation email: #{e.message}")
      # Don't fail the webhook if email sending fails
    end
  end

  def success
    @appointment = Appointment.find(params[:appointment_id])
    @price = Price.find(@appointment.price_id)
  end

  def failure
  end

  private

  # def create_sale(app, customer, metadata = {})
  #   phone_number = extract_phone_number_from_appointment(app)
  #   staff = Staff.find_by(name: "Digital")
  #   price = Price.find(app.price_id)

  #   # Get the actual amount paid (with discount applied if any)
  #   original_amount = metadata['original_amount'].to_f rescue price.amount
  #   discount_amount = metadata['discount_amount'].to_f rescue 0
  #   final_amount = original_amount - discount_amount

  #   sale = Sale.new(
  #     date: app.created_at,
  #     amount_paid: final_amount,
  #     customer_name: app.name,
  #     location: app.location,
  #     payment_method: "Digital",
  #     payment_type: "Full Payment",
  #     customer_phone_number: phone_number,
  #     customer_service_officer_name: "Digital",
  #     product_service_name: price.shoot_type,
  #     customer_id: customer.id,
  #     staff_id: staff.id
  #   )

  #   if discount_amount > 0
  #     sale.discount = discount_amount
  #     sale.discount_reason = "Referral discount (#{metadata['referral_code']})"
  #   end

  #   sale.appointment = app
  #   sale.save
  # end

  # def create_or_update_customer(app)
  #   phone_number = extract_phone_number_from_appointment(app)
  #   customer = Customer.find_by(phone_number: phone_number)
  #   if customer
  #     customer.increment!(:visits_count)
  #   else
  #     customer = Customer.create!(name: app.name, email: app.email, phone_number: phone_number, visits_count: 0)
  #   end
  #   customer
  # end

  # def extract_phone_number_from_appointment(app)
  #   app.questions.find { |q| q.question == 'Phone number' }.answer
  # end

  # def process_referral_conversion(appointment)
  #   referral_code = appointment.referral_source
  #   referral = Referral.find_by(code: referral_code)

  #   return unless referral

  #   # Find the customer related to this appointment
  #   phone_number = extract_phone_number_from_appointment(appointment)
  #   customer = Customer.find_by(phone_number: phone_number)

  #   # Mark referral as converted
  #   referral.mark_as_used(customer)

  #   # Process the reward immediately instead of waiting
  #   reward_amount = referral.reward_amount || 10000
  #   referrer = referral.referrer

  #   # Add credits to referrer's account
  #   referrer.credits += reward_amount
  #   referrer.save

  #   # Mark referral as rewarded
  #   referral.mark_as_rewarded

  #   # Send success email to referrer
  #   ReferralMailer.referral_success_email(referral).deliver_later
  # end

  def handle_coupon_application
    # Reset coupon if removal requested
    current_appointment_id = session[:coupon_appointment_id]

    if current_appointment_id != @appointment.id.to_s
      clear_coupon_session
    end

    if params[:remove_coupon].present?
      clear_coupon_session
      redirect_to make_payment_path(appointment_id: @appointment.id, apply_credits: @credits_applied) and return
    end

    # Apply new coupon if provided
    if params[:coupon_code].present?
      apply_coupon(params[:coupon_code])
    elsif session[:applied_coupon_code].present? && session[:coupon_appointment_id] == @appointment.id.to_s
      # Restore previously applied coupon from session
      restore_coupon_from_session
    else
      clear_coupon_session
    end
  end

  def apply_coupon(coupon_code)
    coupon = Coupon.find_valid_coupon(coupon_code)
    
    if coupon.nil?
      @coupon_error = "Invalid or expired coupon code"
      clear_coupon_session
      return
    end
  
    unless coupon_eligible_for_customer?(coupon)
      @coupon_error = "This coupon is not available for your account"
      clear_coupon_session
      return
    end
  
    # Store successful coupon application WITH appointment ID
    @applied_coupon = coupon
    session[:applied_coupon_code] = coupon.code
    session[:applied_coupon_id] = coupon.id
    session[:coupon_appointment_id] = @appointment.id.to_s  # ADD THIS LINE!
  end

  def restore_coupon_from_session
    coupon = Coupon.find_by(id: session[:applied_coupon_id])
    if coupon&.valid_for_use?
      @applied_coupon = coupon
    else
      clear_coupon_session
    end
  end

  def clear_coupon_session_for_payment
    session.delete(:applied_coupon_code)
    session.delete(:applied_coupon_id)
    session.delete(:coupon_discount)
    session.delete(:coupon_appointment_id)
  end

  def clear_coupon_session
    session.delete(:applied_coupon_code)
    session.delete(:applied_coupon_id)
    session.delete(:coupon_discount)
    session.delete(:coupon_appointment_id)
    @applied_coupon = nil      # Clears instance variables too
    @coupon_discount = 0       # Clears instance variables too
  end

  def calculate_final_amount_with_all_discounts
    @final_amount = @price.amount - @credits_applied
    @final_amount = 0 if @final_amount < 0

    # Apply coupon discount
    @coupon_discount = 0
    if @applied_coupon
      @coupon_discount = @applied_coupon.calculate_discount(@final_amount)
      session[:coupon_discount] = @coupon_discount
      @final_amount -= @coupon_discount
    elsif session[:coupon_discount].present?
      @coupon_discount = session[:coupon_discount].to_i
      @final_amount -= @coupon_discount
    end

    # Apply referral discount (EXISTING LOGIC - UNCHANGED)
    if @appointment.referral_source.present?
      referral = Referral.find_by(code: @appointment.referral_source)
      @referral_discount = referral&.referred_discount || 5000
      @final_amount -= @referral_discount
    end

    @final_amount = 0 if @final_amount < 0
  end

  def coupon_eligible_for_customer?(coupon)
    return true unless coupon.customer_restrictions?
    
    phone_number = extract_phone_number_from_appointment(@appointment)
    customer = Customer.find_by(phone_number: phone_number)
    
    case coupon.coupon_type
    when 'referral'
      # For referral coupons, use existing referral eligibility logic
      Referral.customer_eligible_for_referral?(customer)
    when 'seasonal', 'adhoc', 'percentage', 'fixed_amount'
      # For other coupon types, allow unless specifically restricted
      true
    else
      true
    end
  end

  def process_referral_conversion(appointment, customer)
    referral_code = appointment.referral_source
    Rails.logger.info("Processing referral conversion for code: #{referral_code}, customer: #{customer.id}")


    # Find referral records for this specific conversion (should be in CONVERTED status)
    referral = Referral.where(parent_code: referral_code, status: Referral::CONVERTED, referred_id: customer.id).first
    Rails.logger.info("Found referral by parent_code: #{referral&.id || 'none'}")

    if referral.nil?
      referral = Referral.where(code: referral_code, status: Referral::CONVERTED, referred_id: customer.id).first
      Rails.logger.info("Found referral by code: #{referral&.id || 'none'}")
    end

    if referral.nil?
      Rails.logger.info("No matching referral record found!")
      # Let's check if there are any referrals at all for this customer
      all_referrals = Referral.where(referred_id: customer.id).pluck(:id, :code, :parent_code, :status)
      Rails.logger.info("All referrals for this customer: #{all_referrals}")
      return
    end

    return unless referral

    unless customer.sales.count <= 1 && Referral.customer_eligible_for_referral?(customer)
      return
    end

    # Process the reward
    reward_amount = referral.reward_amount || 10000
    referrer = referral.referrer

    # Add credits to referrer's account
    referrer.credits += reward_amount
    referrer.save

    # Mark referral as rewarded
    referral.mark_as_rewarded

    # Send success email to referrer
    ReferralMailer.referral_success_email(referral).deliver_later

    # Log the successful reward for auditing
    Rails.logger.info("Referral reward of #{reward_amount} applied to customer #{referrer.id} for referral #{referral.id}")
  end

  def determine_layout
    public_actions = ['make_payment', 'initiate_payment', 'verify_payment', 'success']

    if public_actions.include?(action_name)
      'public'
    else
      'application'
    end
  end
end
