# app/controllers/api/base_controller.rb
module Api
  class BaseController < ActionController::API
    include Api::V1::ErrorHandling
    before_action :authenticate_api_request

    private

    def authenticate_api_request
      api_key = request.headers['X-API-Key']
      Rails.logger.debug "Received API key: #{api_key.present? ? '[PRESENT]' : '[MISSING]'}"

      unless api_key.present? && valid_api_key?(api_key)
        Rails.logger.debug "API key validation failed"
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def valid_api_key?(key)
      stored_key = Rails.application.credentials.dig(:api_keys, :wordpress) || ENV['WORDPRESS_API_KEY']
      # Rails.logger.debug "Stored key exists: #{stored_key.present? ? 'Yes' : 'No'}"
      result = key.present? && key == stored_key
      # Rails.logger.debug "Key validation result: #{result}"
      result
    end
  end
end
