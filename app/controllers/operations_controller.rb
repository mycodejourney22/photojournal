class OperationsController < ApplicationController

  def report
    @sales = policy_scope(Sale).where('date >= ? AND date <= ?', Time.zone.now.beginning_of_month, Time.zone.now.end_of_month)
                               .group("DATE(date)")
                               .sum(:amount_paid)
    @total_sales = @sales.values.sum
  end
end
