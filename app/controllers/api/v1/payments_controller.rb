# app/controllers/api/v1/payments_controller.rb
module Api
  module V1
    class PaymentsController < Api::BaseController
      def initiate
        appointment = Appointment.find_by(uuid: params[:appointment_uuid])

        if !appointment
          return render json: { error: 'Appointment not found' }, status: :not_found
        end

        if !appointment.price_id
          return render json: { error: 'No payment required for this appointment' }, status: :bad_request
        end

        if appointment.payment_status
          return render json: { error: 'Payment already completed for this appointment' }, status: :bad_request
        end

        price = Price.find(appointment.price_id)
        email = appointment.email || "default@example.com"

        # Apply referral discount if applicable
        amount = price.amount.to_f
        referral_discount = 0

        if appointment.referral_source.present?
          referral = Referral.find_by(code: appointment.referral_source)
          referral_discount = referral&.referred_discount || 0
          amount = [amount - referral_discount, 0].max
        end

        # Convert to kobo (smallest currency unit) for Paystack
        paystack_amount = (amount * 100).to_i



        # Initialize Paystack transaction
        begin
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
              original_amount: amount.to_f,
              discount_amount: referral_discount.to_f,
              referral_code: appointment.referral_source
            }
          }.to_json
          Rails.logger.info "Paystack request body: #{request.body.inspect}"
          response = http.request(request)
          Rails.logger.info "Paystack response code: #{response.code}"
          Rails.logger.info "Paystack response body: #{response.body}"

          if response.code == "200"
            parsed_response = JSON.parse(response.body)

            if parsed_response['status'] == true
              render json: {
                success: true,
                payment_url: parsed_response["data"]["authorization_url"],
                reference: parsed_response["data"]["reference"],
                amount: amount,
                original_amount: price.amount,
                discount_amount: referral_discount
              }
            else
              render json: {
                success: false,
                error: parsed_response['message'] || "Payment initiation failed"
              }, status: :unprocessable_entity
            end
          else
            render json: {
              success: false,
              error: "Failed to connect to payment gateway. HTTP Status: #{response.code}"
            }, status: :service_unavailable
          end
        rescue => e
          render json: {
            success: false,
            error: "Payment service error: #{e.message}"
          }, status: :internal_server_error
        end
      end

      def verify
        reference = params[:reference]

        if reference.blank?
          return render json: { error: "Payment reference is required" }, status: :bad_request
        end

        begin
          uri = URI("https://api.paystack.co/transaction/verify/#{reference}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 10
          http.read_timeout = 15

          request = Net::HTTP::Get.new(uri)
          request['Authorization'] = "Bearer #{ENV['PAYSTACK_SECRET_KEY']}"

          response = http.request(request)

          if response.is_a?(Net::HTTPSuccess)
            response_body = JSON.parse(response.body)

            if response_body['status'] && response_body['data']['status'] == "success"
              # Extract appointment UUID from metadata
              appointment_uuid = response_body['data']['metadata']['appointment_uuid'] rescue nil

              if appointment_uuid.blank?
                return render json: { success: false, error: "Could not find booking information" }, status: :bad_request
              end

              # Find appointment
              appointment = Appointment.find_by(uuid: appointment_uuid)

              if appointment.nil?
                return render json: { success: false, error: "Booking information not found" }, status: :not_found
              end

              if appointment.payment_status
                return render json: { success: true, message: "Payment was already processed", appointment_uuid: appointment.uuid }
              end

              # Process the payment using your existing logic
              appointment.update(payment_status: true)

              # Create sale record - simplified version that would use your existing payment processor code
              phone_number = appointment.questions.find { |q| q.question == 'Phone number' }&.answer
              staff = Staff.find_by(name: "Digital") || Staff.first
              price = appointment.price

              original_amount = price.amount
              metadata = response_body['data']['metadata'] || {}
              discount_amount = metadata['discount_amount'].to_f rescue 0

              sale = Sale.new(
                date: Time.current,
                amount_paid: response_body['data']['amount'] / 100.0,
                customer_name: appointment.name,
                location: appointment.location,
                payment_method: "Digital",
                payment_type: "Full Payment",
                customer_phone_number: phone_number,
                product_service_name: price&.name || "PhotoShoot",
                staff_id: staff.id,
                appointment: appointment,
                discount: discount_amount,
                discount_reason: appointment.referral_source.present? ? "Referral discount" : nil
              )

              if sale.save
                render json: {
                  success: true,
                  message: "Payment verified successfully",
                  appointment_uuid: appointment.uuid
                }
              else
                render json: {
                  success: false,
                  error: "Payment verified but failed to create sales record",
                  errors: sale.errors.full_messages
                }, status: :unprocessable_entity
              end
            else
              error_message = response_body['message'] || "Verification failed"
              render json: { success: false, error: error_message }, status: :payment_required
            end
          else
            render json: {
              success: false,
              error: "Failed to verify payment: HTTP #{response.code}"
            }, status: :service_unavailable
          end
        rescue => e
          render json: {
            success: false,
            error: "Payment verification error: #{e.message}"
          }, status: :internal_server_error
        end
      end
    end
  end
end
