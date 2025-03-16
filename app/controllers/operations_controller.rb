class OperationsController < ApplicationController

  def index
    timezone = timezone_for_africa
    date_sql = date_in_timezone_sql(timezone)

    @sales = policy_scope(Sale)
      .where(void: false)
      .where(date: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month)
      .group(Arel.sql(date_sql))
      .order(Arel.sql("#{date_sql} DESC"))
      .sum(:amount_paid)

    @total_sales = @sales.values.sum
  end

  def daily_sales
    timezone = timezone_for_africa
    @date = Date.parse(params[:date])

    # Use a different approach that will work with bind parameters
    @daily_sales = policy_scope(Sale).where(
      "DATE(date AT TIME ZONE 'UTC' AT TIME ZONE ?) = ?",
      timezone,
      @date
    )
  end

  private

  def timezone_for_africa
    "Africa/Lagos" # West Central Africa timezone
  end

  def date_in_timezone_sql(timezone)
    "DATE(date AT TIME ZONE 'UTC' AT TIME ZONE '#{timezone}')"
  end
end
