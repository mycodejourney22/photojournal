class PaymentsController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  def initiate_payment
    price = Price.find(params[:price_id])
    email = current_user&.email || "default@example.com" # Adjust to fetch your customer email
    amount = (price.amount * 100).to_i # Convert to kobo

    uri = URI("https://api.paystack.co/transaction/initialize")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"
    request['Content-Type'] = 'application/json'
    request.body = { email: email, amount: amount }.to_json

    begin
      response = http.request(request)
      Rails.logger.info("Paystack Response: #{response.body}")

      if response.code == "200"
        parsed_response = JSON.parse(response.body)

        if parsed_response['status'] == true
          redirect_to parsed_response['data']['authorization_url'], allow_other_host: true
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
end
