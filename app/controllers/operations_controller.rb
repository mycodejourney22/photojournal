class OperationsController < ApplicationController

  def index
    # Use a proper IANA timezone name for your region
    timezone = "Africa/Lagos"  # This is the timezone for West Central Africa

    date_sql = "DATE(date AT TIME ZONE 'UTC' AT TIME ZONE '#{timezone}')"

    @sales = policy_scope(Sale)
      .where(void: false)
      .where(date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)
      .group(Arel.sql(date_sql))
      .order(Arel.sql("#{date_sql} DESC"))
      .sum(:amount_paid)

    @total_sales = @sales.values.sum
  end

  def daily_sales
    @date = Date.parse(params[:date])
    @daily_sales = policy_scope(Sale).where('date::date = ?', @date)
  end
end
