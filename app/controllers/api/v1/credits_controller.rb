# app/controllers/api/v1/credits_controller.rb
module Api
  module V1
    class CreditsController < Api::BaseController
      include PhoneNumberNormalizer # Make sure to include your existing normalizer

      def check
        email = params[:email]
        phone = params[:phone]

        if email.blank? && phone.blank?
          return render json: { error: "Email or phone number is required" }, status: :bad_request
        end

        customer = find_customer(email, phone)

        if customer && customer.credits > 0
          render json: {
            customer_found: true,
            customer_id: customer.id,
            name: customer.name,
            credits: customer.credits,
            email: customer.email,
            phone: customer.phone_number
          }
        elsif customer
          render json: {
            customer_found: true,
            customer_id: customer.id,
            name: customer.name,
            credits: 0,
            email: customer.email,
            phone: customer.phone_number
          }
        else
          render json: { customer_found: false }
        end
      end

      private

      def find_customer(email, phone)
        if email.present?
          customer = Customer.find_by(email: email)
          return customer if customer
        end

        if phone.present?
          normalized_phone = normalize_phone_number(phone)
          customer = Customer.find_by(phone_number: normalized_phone)
          return customer if customer
        end

        nil
      end
    end
  end
end
