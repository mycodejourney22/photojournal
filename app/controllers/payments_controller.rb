class PaymentsController < ApplicationController
  skip_before_action :authenticate_user!
  require 'net/http'
  require 'uri'
  require 'json'

  def make_payment
    @appointment = Appointment.find(params[:appointment_id])
    @price = Price.find(@appointment.price_id)
  end

  def initiate_payment
    appointment = Appointment.find(params[:appointment_id])
    price = Price.find(params[:price_id])
    email = appointment.email || "default@example.com"
    amount = (price.amount * 100).to_i


    uri = URI("https://api.paystack.co/transaction/initialize")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    request['Content-Type'] = 'application/json'
    request.body = { email: email, amount: amount, metadata: {
      appointment_uuid: appointment.uuid # Add the appointment UUID here
    } }.to_json

    begin
      response = http.request(request)
      # Rails.logger.info("Paystack Response: #{response.body}")

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

    uri = URI("https://api.paystack.co/transaction/verify/#{reference}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    # Use GET request instead of POST
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    # puts "Response Code: #{response.code}"
    # puts "Response Body: #{response.body.inspect}"

    if response.is_a?(Net::HTTPSuccess)
      response_body = JSON.parse(response.body)

      if response_body['status'] && response_body['data']['status'] == "success"
        # Handle successful payment
        appointment = Appointment.find_by(uuid: response_body['data']['metadata']['appointment_uuid'])
        appointment.update(payment_status: true)
        customer = create_or_update_customer(appointment)
        create_sale(appointment, customer)
        redirect_to success_payments_path(appointment_id: appointment.id)
      else
        redirect_to failure_payments_path, alert: "Payment verification failed."
      end
    else
      redirect_to failure_payments_path, alert: "Failed to communicate with payment gateway."
    end
  end

  def success
    @appointment = Appointment.find(params[:appointment_id])
    @price = Price.find(@appointment.price_id)
  end

  def failure
  end


  private

  def create_sale(app, customer)
    phone_number = extract_phone_number_from_appointment(app)
    staff = Staff.find_by(name: "Digital")
    price = Price.find(app.price_id)
    sale = Sale.new(date: app.created_at, amount_paid: price.amount, customer_name: app.name,
                    location: app.location, payment_method: "Digital", payment_type: "Full Payment",
                    customer_phone_number: phone_number, customer_service_officer_name: "Digital",
                    product_service_name: price.shoot_type, customer_id: customer.id, staff_id: staff.id)
    sale.appointment = app
    sale.save
  end

  def create_or_update_customer(app)
    phone_number = extract_phone_number_from_appointment(app)
    customer = Customer.find_by(phone_number: phone_number)
    if customer
      customer.increment!(:visits_count)
    else
      customer = Customer.create!(name: app.name, email: app.email, phone_number: phone_number, visits_count: 0)
    end
    customer
  end

  def extract_phone_number_from_appointment(app)
    app.questions.find { |q| q.question == 'Phone number' }.answer
  end

end
