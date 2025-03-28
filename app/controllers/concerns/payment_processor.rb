# app/controllers/concerns/payment_processor.rb
module PaymentProcessor
  extend ActiveSupport::Concern
  include PhoneNumberNormalizer # Include your existing normalizer

  # Process a successful payment
  # def process_successful_payment(appointment, metadata = {})
  #   return false if appointment.nil? || appointment.payment_status?

  #   # Update appointment payment status
  #   appointment.update(payment_status: true)

  #   # Create customer and sale
  #   customer = create_or_update_customer(appointment)
  #   create_sale(appointment, customer, metadata)

  #   # Process referral if present
  #   if appointment.referral_source.present?
  #     process_referral_conversion(appointment, customer)
  #   end

  #   # Clear session data
  #   session.delete(:referral_code) if defined?(session)

  #   Rails.logger.info("Payment successfully processed for appointment #{appointment.id}")
  #   true
  # end

  def create_or_update_customer(appointment)
    phone_number = extract_phone_number_from_appointment(appointment)
    customer = Customer.find_by(phone_number: normalize_phone_number(phone_number))

    if customer
      customer.increment!(:visits_count)
    else
      customer = Customer.create!(
        name: appointment.name,
        email: appointment.email,
        phone_number: normalize_phone_number(phone_number),
        visits_count: 1
      )
    end

    customer
  end

  def create_sale(appointment, customer, metadata = {})
    phone_number = extract_phone_number_from_appointment(appointment)
    staff = Staff.find_by(name: "Digital") || Staff.first
    price = Price.find(appointment.price_id) if appointment.price_id.present?

    # Get the actual amount paid (with discount applied if any)
    original_amount = metadata['original_amount'].to_f rescue price&.amount.to_f
    discount_amount = metadata['discount_amount'].to_f rescue 0
    final_amount = [original_amount - discount_amount, 0].max

    sale = Sale.new(
      date: appointment.created_at,
      amount_paid: final_amount,
      customer_name: appointment.name,
      location: appointment.location,
      payment_method: "Digital",
      payment_type: "Full Payment",
      customer_phone_number: phone_number,
      customer_service_officer_name: "Digital",
      product_service_name: price&.shoot_type || "PhotoShoot",
      customer_id: customer.id,
      staff_id: staff.id,
      appointment: appointment
    )

    if discount_amount > 0
      sale.discount = discount_amount
      sale.discount_reason = "Referral discount (#{metadata['referral_code']})"
    end

    sale.save!
    sale
  end

  # def process_referral_conversion(appointment, customer)
  #   referral_code = appointment.referral_source
  #   Rails.logger.info("Processing referral conversion for code: #{referral_code}, customer: #{customer.id}")

  #   # Find referral records for this specific conversion
  #   referral = Referral.where(parent_code: referral_code, status: Referral::CONVERTED, referred_id: customer.id).first
  #   referral ||= Referral.where(code: referral_code, status: Referral::CONVERTED, referred_id: customer.id).first

  #   if referral.nil?
  #     Rails.logger.info("No matching referral record found!")
  #     return
  #   end

  #   unless customer.sales.count <= 1 && Referral.customer_eligible_for_referral?(customer)
  #     return
  #   end

  #   # Process the reward
  #   reward_amount = referral.reward_amount || 10000
  #   referrer = referral.referrer

  #   # Add credits to referrer's account
  #   referrer.credits += reward_amount
  #   referrer.save

  #   # Mark referral as rewarded
  #   referral.mark_as_rewarded

  #   # Send success email to referrer
  #   ReferralMailer.referral_success_email(referral).deliver_later

  #   Rails.logger.info("Referral reward of #{reward_amount} applied to customer #{referrer.id} for referral #{referral.id}")
  # end

  def extract_phone_number_from_appointment(appointment)
    appointment.questions.find { |q| q.question == 'Phone number' }&.answer
  end
end
