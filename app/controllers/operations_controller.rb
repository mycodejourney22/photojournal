class OperationsController < ApplicationController

  def index
    @sales = policy_scope(Sale)
      .where(void: false)
      .where(date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)
      .group("DATE(date)")
      .order("DATE(date) DESC")
      .sum(:amount_paid)
      @total_sales = @sales.values.sum
  end

  def daily_sales
    @date = Date.parse(params[:date])
    @daily_sales = policy_scope(Sale).where('date::date = ?', @date)
  end
end
