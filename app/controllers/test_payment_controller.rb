class TestPaymentController < ApplicationController

  def display_price
    @price = Price.first
  end
end
