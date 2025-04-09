# app/controllers/api/v1/prices_controller.rb
module Api
  module V1
    class PricesController < Api::BaseController
      def index
        @prices = Price.where(still_valid: true)
        render json: @prices
      end

      def show
        @price = Price.find(params[:id])
        render json: @price
      end
    end
  end
end
