# app/controllers/api/v1/referrals_controller.rb
module Api
  module V1
    class ReferralsController < Api::BaseController
      def validate
        code = params[:code]

        if code.blank?
          return render json: { valid: false, error: "Referral code is required" }, status: :bad_request
        end

        referral = Referral.where(code: code, status: Referral::ACTIVE).first

        if referral
          render json: {
            valid: true,
            discount_amount: referral.referred_discount || 5000,
            referrer_name: referral.referrer.name
          }
        else
          render json: { valid: false, error: "Invalid or expired referral code" }
        end
      end
    end
  end
end
