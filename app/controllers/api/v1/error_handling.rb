# app/controllers/api/v1/error_handling.rb
module Api
  module V1
    module ErrorHandling
      extend ActiveSupport::Concern

      included do
        rescue_from ActiveRecord::RecordNotFound do |e|
          render json: { error: "Resource not found: #{e.message}" }, status: :not_found
        end

        rescue_from ActiveRecord::RecordInvalid do |e|
          render json: { error: e.message, details: e.record.errors }, status: :unprocessable_entity
        end

        rescue_from ActionController::ParameterMissing do |e|
          render json: { error: e.message }, status: :bad_request
        end

        rescue_from StandardError do |e|
          if Rails.env.development? || Rails.env.test?
            render json: { error: e.message, backtrace: e.backtrace }, status: :internal_server_error
          else
            render json: { error: "An internal error occurred" }, status: :internal_server_error

            # Log the error
            Rails.logger.error("API ERROR: #{e.message}")
            Rails.logger.error(e.backtrace.join("\n"))
          end
        end
      end
    end
  end
end
