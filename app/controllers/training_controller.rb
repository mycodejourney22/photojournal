# # app/controllers/training_controller.rb
# class TrainingController < ApplicationController
#   skip_before_action :authenticate_user!
#   layout 'training'

#   def index
#     # Public training landing page - no authentication required
#   end

#   def enroll
#     @enrollment = TrainingEnrollment.new(enrollment_params)

#     if @enrollment.save
#       # Send notification email to admin
#       TrainingEnrollmentMailer.admin_notification(@enrollment).deliver_later

#       # Send confirmation email to applicant
#       TrainingEnrollmentMailer.applicant_confirmation(@enrollment).deliver_later

#       redirect_to training_path, notice: "Thank you for your application, #{@enrollment.first_name}! We'll contact you within 24 hours."
#     else
#       redirect_to training_path, alert: "Something went wrong: #{@enrollment.errors.full_messages.join(', ')}"
#     end
#   end

#   private

#   def enrollment_params
#     params.permit(:first_name, :last_name, :email, :phone, :program, :experience, :message)
#   end
# end
# app/controllers/training_controller.rb
class TrainingController < ApplicationController
  skip_before_action :authenticate_user!
  include PhoneNumberNormalizer

  layout 'training'

  def index
    # Public training landing page - no authentication required
  end

  def enroll
    @enrollment = TrainingEnrollment.new(enrollment_params)

    if @enrollment.save
      # Redirect to payment page
      redirect_to training_payment_path(enrollment_id: @enrollment.id)
    else
      redirect_to training_path, alert: "Something went wrong: #{@enrollment.errors.full_messages.join(', ')}"
    end
  end

  def payment
    @enrollment = TrainingEnrollment.find_by(id: params[:enrollment_id])

    if @enrollment.nil?
      redirect_to training_path, alert: "Enrollment not found."
      return
    end

    if @enrollment.paid?
      redirect_to training_success_path(enrollment_id: @enrollment.id), notice: "You have already completed payment."
      return
    end

    @amount = @enrollment.program_price
  end

  def initiate_payment
    @enrollment = TrainingEnrollment.find_by(id: params[:enrollment_id])

    if @enrollment.nil?
      redirect_to training_path, alert: "Enrollment not found."
      return
    end

    if @enrollment.paid?
      redirect_to training_success_path(enrollment_id: @enrollment.id)
      return
    end

    amount = @enrollment.program_price
    email = @enrollment.email

    # Convert to kobo for Paystack
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
      callback_url: training_verify_payment_url,
      metadata: {
        training_enrollment_uuid: @enrollment.uuid,
        enrollment_type: 'training',
        program: @enrollment.program,
        amount: amount.to_f,
        customer_name: @enrollment.full_name
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
          redirect_to training_payment_path(enrollment_id: @enrollment.id)
        end
      else
        flash[:error] = "Failed to connect to Paystack. Please try again."
        redirect_to training_payment_path(enrollment_id: @enrollment.id)
      end
    rescue Timeout::Error, SocketError => e
      flash[:error] = "Connection to payment gateway failed. Please try again later."
      Rails.logger.error("Paystack Timeout/Socket Error: #{e.message}")
      redirect_to training_payment_path(enrollment_id: @enrollment.id)
    rescue => e
      flash[:error] = "An error occurred. Please try again."
      Rails.logger.error("Paystack Error: #{e.message}")
      redirect_to training_payment_path(enrollment_id: @enrollment.id)
    end
  end

  def verify_payment
    reference = params[:reference]

    if reference.blank?
      redirect_to training_path, alert: "Invalid payment reference."
      return
    end

    begin
      uri = URI("https://api.paystack.co/transaction/verify/#{reference}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 15

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
      request['Content-Type'] = "application/json"

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        response_body = JSON.parse(response.body)

        if response_body['status'] && response_body['data']['status'] == "success"
          enrollment_uuid = response_body['data']['metadata']['training_enrollment_uuid'] rescue nil

          if enrollment_uuid.blank?
            Rails.logger.error("Transaction #{reference} has no training enrollment UUID in metadata")
            redirect_to training_failure_path, alert: "Could not find enrollment information"
            return
          end

          enrollment = TrainingEnrollment.find_by(uuid: enrollment_uuid)

          if enrollment.nil?
            Rails.logger.error("TrainingEnrollment with UUID #{enrollment_uuid} not found")
            redirect_to training_failure_path, alert: "Enrollment not found"
            return
          end

          if enrollment.paid?
            Rails.logger.info("Payment for enrollment #{enrollment.id} already processed")
            redirect_to training_success_path(enrollment_id: enrollment.id)
            return
          end

          # Process the payment
          process_successful_payment(enrollment, response_body['data'])

          redirect_to training_success_path(enrollment_id: enrollment.id)
        else
          redirect_to training_failure_path, alert: "Payment verification failed."
        end
      else
        redirect_to training_failure_path, alert: "Failed to verify payment."
      end
    rescue => e
      Rails.logger.error("Exception during training payment verification: #{e.class} - #{e.message}")
      redirect_to training_failure_path, alert: "An error occurred during payment verification."
    end
  end

  def success
    @enrollment = TrainingEnrollment.find_by(id: params[:enrollment_id])

    if @enrollment.nil?
      redirect_to training_path, alert: "Enrollment not found."
      return
    end
  end

  def failure
    # Payment failed page
  end

  private

  def enrollment_params
    params.permit(:first_name, :last_name, :email, :phone, :program, :experience, :message)
  end

  def process_successful_payment(enrollment, payment_data)
    # Mark enrollment as paid
    enrollment.mark_as_paid!

    # Create or update customer
    customer = find_or_create_customer(enrollment)
    enrollment.update(customer_id: customer.id) if customer

    # Create sale record
    create_training_sale(enrollment, customer, payment_data)

    # Send confirmation emails
    TrainingEnrollmentMailer.admin_notification(enrollment).deliver_later
    TrainingEnrollmentMailer.applicant_confirmation(enrollment).deliver_later

    Rails.logger.info("Successfully processed training payment for enrollment #{enrollment.id}")
  end

  def find_or_create_customer(enrollment)
    normalized_phone = normalize_phone_number(enrollment.phone)
    customer = Customer.find_by(phone_number: normalized_phone)

    if customer
      customer.increment!(:visits_count)
    else
      customer = Customer.create!(
        name: enrollment.full_name,
        email: enrollment.email,
        phone_number: normalized_phone,
        visits_count: 1
      )
    end

    customer
  end

  def create_training_sale(enrollment, customer, payment_data)
    staff = Staff.find_by(name: "Digital") || Staff.first

    sale = Sale.new(
      date: Time.current,
      amount_paid: enrollment.program_price,
      customer_name: enrollment.full_name,
      location: "Online",
      payment_method: "Digital",
      payment_type: "Full Payment",
      customer_phone_number: enrollment.phone,
      customer_service_officer_name: "Digital",
      product_service_name: "Training",
      customer_id: customer&.id,
      staff_id: staff.id
    )

    if sale.save
      Rails.logger.info("Created training sale #{sale.id} for enrollment #{enrollment.id}")
    else
      Rails.logger.error("Failed to create sale for enrollment #{enrollment.id}: #{sale.errors.full_messages.join(', ')}")
    end

    sale
  end
end
