class CustomersAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def index
    # Set default date range if not provided
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

    # Load customer analytics based on filters
    load_customer_analytics
  end

  def export
    # Set date range
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

    # Determine what to export
    export_type = params[:export_type] || 'all_customers'

    case export_type
    when 'top_spenders'
      customers = export_top_spenders
      filename = "top_spenders_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}.csv"
    when 'frequent_visitors'
      customers = export_frequent_visitors
      filename = "frequent_visitors_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}.csv"
    when 'customers_with_credits'
      customers = export_customers_with_credits
      filename = "customers_with_credits_#{Date.today.strftime('%Y%m%d')}.csv"
    else
      customers = export_all_customers
      filename = "all_customers_#{@start_date.strftime('%Y%m%d')}_to_#{@end_date.strftime('%Y%m%d')}.csv"
    end
  end

  def top_spenders
    # Set default date range if not provided
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today
    @limit = (params[:limit] || 25).to_i

    # Base query for sales within the date range
    base_sales_query = Sale.where(date: @start_date.beginning_of_day..@end_date.end_of_day)
                           .where(void: false)

    # Get top spending customers
    @top_spenders = Customer.joins(:sales)
                          .merge(base_sales_query)
                          .select('customers.*,
                                  SUM(sales.amount_paid) as total_spent,
                                  COUNT(DISTINCT sales.id) as transaction_count,
                                  MAX(sales.date) as last_purchase')
                          .group('customers.id')
                          .order('total_spent DESC')
                          .limit(@limit)

    # Calculate spending distribution
    all_customers_spending = Customer.joins(:sales)
                                   .merge(base_sales_query)
                                   .select('customers.id, SUM(sales.amount_paid) as spent')
                                   .group('customers.id')
                                   .order('spent DESC')
                                   .pluck('SUM(sales.amount_paid) as spent')

    total_customers = all_customers_spending.size

    if total_customers > 0
      # Calculate distribution numbers
      top_10_percent_count = (total_customers * 0.1).ceil
      top_10_percent_spend = all_customers_spending.take(top_10_percent_count).sum

      middle_40_percent_start = top_10_percent_count
      middle_40_percent_end = middle_40_percent_start + (total_customers * 0.4).ceil
      middle_40_percent_spend = all_customers_spending[middle_40_percent_start...middle_40_percent_end].sum

      bottom_50_percent_spend = all_customers_spending.drop(middle_40_percent_end).sum

      @spending_distribution = {
        top_10_percent: top_10_percent_spend,
        middle_40_percent: middle_40_percent_spend,
        bottom_50_percent: bottom_50_percent_spend
      }
    else
      @spending_distribution = {
        top_10_percent: 0,
        middle_40_percent: 0,
        bottom_50_percent: 0
      }
    end
  end

  private

  def load_customer_analytics
    # Base query for sales within the date range
    base_sales_query = Sale.where(date: @start_date.beginning_of_day..@end_date.end_of_day)
                           .where(void: false)
    if params[:location].present? && params[:location] != 'All Locations'
      base_sales_query = base_sales_query.where(location: params[:location])
    end

    # Total customer count with any activity in period
    @total_customers = Customer.joins(:sales)
                              .merge(base_sales_query)
                              .distinct.count

    # Top customers by total spend
    @top_customers_by_spend = Customer.joins(:sales)
                                    .merge(base_sales_query)
                                    .select('customers.*, SUM(sales.amount_paid) as total_spent')
                                    .group('customers.id')
                                    .order('total_spent DESC')
                                    .limit(20)

    # Top customers by visit count
    @top_customers_by_visits = Customer.order(visits_count: :desc).limit(20)

    # Recent customers
    @recent_customers = Customer.joins(:sales)
                              .merge(base_sales_query)
                              .select('customers.*, MAX(sales.date) as last_visit')
                              .group('customers.id')
                              .order('last_visit DESC')
                              .limit(10)

    # Customers with highest average spend
    @customers_highest_avg_spend = Customer.joins(:sales)
                                         .merge(base_sales_query)
                                         .select('customers.*, AVG(sales.amount_paid) as avg_spend, COUNT(sales.id) as transaction_count')
                                         .group('customers.id')
                                         .having('COUNT(sales.id) >= 2') # At least 2 transactions
                                         .order('avg_spend DESC')
                                         .limit(10)

    # Customers with credits
    @customers_with_credits = Customer.where('credits > 0')
                                    .order(credits: :desc)
                                    .limit(10)

    # Customer sales by location
    @sales_by_location = base_sales_query
                        .joins(:customer)
                        .group(:location)
                        .select('location, COUNT(DISTINCT customer_id) as customer_count, SUM(amount_paid) as total_sales')
                        .order('total_sales DESC')

    # Customer acquisition over time (new customers by month)
    @customer_acquisition = Customer.joins(:sales)
                            .where('sales.date >= ?', @start_date.beginning_of_month)
                            .where('sales.date <= ?', @end_date.end_of_day)
                            .select("customers.id, MIN(sales.date) as first_purchase_date")
                            .group("customers.id")
                            .order("first_purchase_date")

    monthly_acquisitions = {}
    @customer_acquisition.each do |customer|
      purchase_month = customer.first_purchase_date.beginning_of_month
      monthly_acquisitions[purchase_month] ||= 0
      monthly_acquisitions[purchase_month] += 1
    end

    # Sort by month and format for the chart
    @customer_acquisition_data = monthly_acquisitions.sort_by { |month, _| month }.map do |month, count|
      { month: month.strftime('%b %Y'), new_customers: count }
    end

    # Customer retention rate (returning customers / total customers)
    repeat_customers = Customer.joins(:sales)
                              .merge(base_sales_query)
                              .group('customers.id')
                              .having('COUNT(sales.id) > 1')
                              .count

    @retention_rate = @total_customers > 0 ? (repeat_customers.count.to_f / @total_customers * 100).round(2) : 0

    # Total revenue from repeat customers
    @repeat_customer_revenue = base_sales_query
                              .joins(:customer)
                              .where(customer_id: repeat_customers.keys)
                              .sum(:amount_paid)

    # Average spend per customer
    @average_customer_spend = @total_customers > 0 ? (base_sales_query.sum(:amount_paid).to_f / @total_customers).round(2) : 0
  end

  def authorize_admin
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      flash[:alert] = "You are not authorized to access this page."
      redirect_to root_path
    end
  end
end
