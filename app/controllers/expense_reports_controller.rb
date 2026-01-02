# app/controllers/expense_reports_controller.rb
class ExpenseReportsController < ApplicationController
  before_action :set_date_range
  before_action :set_location_filter
  before_action :set_category_filter

  def index
    authorize :expense_report, :index?

    # Get base expenses based on filters
    @expenses = filtered_expenses

    # Calculate metrics
    @total_expenses = calculate_total_expenses
    @expense_count = calculate_expense_count
    @average_expense = calculate_average_expense
    @top_category = calculate_top_category
    @period_change = calculate_period_change

    # Chart data
    @daily_expenses_chart_data = daily_expenses_chart_data
    @category_chart_data = category_chart_data

    # Breakdowns
    @location_breakdown = location_breakdown
    @category_breakdown = category_breakdown

    # Recent expenses
    @recent_expenses = @expenses.order(date: :desc).limit(10)

    # Available filters
    @available_locations = ['Ikeja', 'Surulere', 'Ajah', 'General']
    @available_categories = [
      'Office Monthly Supplies',
      'Data Subscription',
      'Delivery',
      'Frame/Photobook production',
      'Diesel',
      'Petrol',
      'Transport',
      'Studio Props',
      'Studio Gadget',
      'Electricity'
    ]

    respond_to do |format|
      format.html
      format.csv { send_csv_export }
    end
  end

  private

  def set_date_range
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    @end_date = [@end_date, Date.today].min
    @start_date = [@start_date, @end_date].min
  end

  def set_location_filter
    @selected_location = params[:location].present? && params[:location] != 'All Locations' ? params[:location] : nil
  end

  def set_category_filter
    @selected_category = params[:category].present? && params[:category] != 'All Categories' ? params[:category] : nil
  end

  def filtered_expenses
    expenses = Expense.where(date: @start_date..@end_date)
    expenses = expenses.where('location ILIKE ?', "%#{@selected_location}%") if @selected_location.present?
    expenses = expenses.where(category: @selected_category) if @selected_category.present?
    expenses
  end

  def calculate_total_expenses
    filtered_expenses.sum(:amount) || 0
  end

  def calculate_expense_count
    filtered_expenses.count
  end

  def calculate_average_expense
    count = calculate_expense_count
    return 0 if count.zero?
    (calculate_total_expenses.to_f / count).round(0)
  end

  def calculate_top_category
    result = filtered_expenses.group(:category).sum(:amount).max_by { |_, v| v }
    result ? result[0] : 'N/A'
  end

  def calculate_period_change
    current_total = calculate_total_expenses

    # Calculate previous period of same length
    period_length = (@end_date - @start_date).to_i + 1
    previous_start = @start_date - period_length.days
    previous_end = @start_date - 1.day

    previous_expenses = Expense.where(date: previous_start..previous_end)
    previous_expenses = previous_expenses.where('location ILIKE ?', "%#{@selected_location}%") if @selected_location.present?
    previous_expenses = previous_expenses.where(category: @selected_category) if @selected_category.present?
    previous_total = previous_expenses.sum(:amount) || 0

    return 0 if previous_total.zero?
    (((current_total - previous_total).to_f / previous_total) * 100).round(1)
  end

  def daily_expenses_chart_data
    daily_data = {}

    (@start_date..@end_date).each do |date|
      daily_data[date.strftime("%b %d")] = 0
    end

    expenses_by_day = filtered_expenses.group(:date).sum(:amount)

    expenses_by_day.each do |date, amount|
      if date >= @start_date && date <= @end_date
        daily_data[date.strftime("%b %d")] = amount
      end
    end

    daily_data.map { |date, amount| { date: date, amount: amount } }
  end

  def category_chart_data
    filtered_expenses.group(:category).sum(:amount).map do |category, amount|
      { category: category, amount: amount }
    end.sort_by { |item| -item[:amount] }
  end

  def location_breakdown
    locations = @selected_location ? [@selected_location] : @available_locations

    total_all = filtered_expenses.sum(:amount)
    total_all = 1 if total_all.zero? # Prevent division by zero

    locations && locations.map do |location|
      location_expenses = filtered_expenses.where('location ILIKE ?', "%#{location}%")
      total = location_expenses.sum(:amount) || 0
      count = location_expenses.count

      {
        location: location,
        total: total,
        count: count,
        percentage: ((total.to_f / total_all) * 100).round(1)
      }
    end.sort_by { |item| -item[:total] }
  end

  def category_breakdown
    total_all = filtered_expenses.sum(:amount)
    total_all = 1 if total_all.zero?

    filtered_expenses.group(:category).sum(:amount).map do |category, total|
      count = filtered_expenses.where(category: category).count
      {
        category: category,
        total: total,
        count: count,
        percentage: ((total.to_f / total_all) * 100).round(1)
      }
    end.sort_by { |item| -item[:total] }
  end

  def send_csv_export
    csv_data = generate_csv_data

    filename = "expense_reports_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}"
    filename += "_#{@selected_location.downcase}" if @selected_location
    filename += "_#{@selected_category.downcase.gsub(' ', '_')}" if @selected_category
    filename += ".csv"

    send_data csv_data,
              type: 'text/csv',
              filename: filename,
              disposition: 'attachment'
  end

  def generate_csv_data
    require 'csv'

    CSV.generate do |csv|
      csv << ["363 Photography Expense Reports"]
      csv << ["Period: #{@start_date.strftime('%B %d, %Y')} - #{@end_date.strftime('%B %d, %Y')}"]
      csv << []

      # Summary
      csv << ["Summary Metrics"]
      csv << ["Total Expenses", @total_expenses]
      csv << ["Total Transactions", @expense_count]
      csv << ["Average Expense", @average_expense]
      csv << ["Top Category", @top_category]
      csv << ["Period Change %", @period_change]
      csv << []

      # Location breakdown
      csv << ["Expenses by Location"]
      csv << ["Location", "Total", "Count", "Percentage"]
      @location_breakdown.each do |item|
        csv << [item[:location], item[:total], item[:count], "#{item[:percentage]}%"]
      end
      csv << []

      # Category breakdown
      csv << ["Expenses by Category"]
      csv << ["Category", "Total", "Count", "Percentage"]
      @category_breakdown.each do |item|
        csv << [item[:category], item[:total], item[:count], "#{item[:percentage]}%"]
      end
      csv << []

      # All expenses
      csv << ["All Expenses"]
      csv << ["Date", "Description", "Category", "Staff", "Amount", "Location"]
      filtered_expenses.order(date: :desc).each do |expense|
        csv << [
          expense.date,
          expense.description,
          expense.category,
          expense.staff_name,
          expense.amount,
          expense.location
        ]
      end
    end
  end
end
