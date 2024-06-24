class ReportsController < ApplicationController

  def dashboard
    @total_payment = PhotoShoot.where(date: Time.current.beginning_of_month..Time.current).sum(:payment_total)
    @total_selection = PhotoShoot.where(date: Time.current.beginning_of_month..Time.current).sum(:number_of_selections)
    @total_shoot = PhotoShoot.where(date: Time.current.beginning_of_month..Time.current).count(:id)
    @avg_selection = PhotoShoot.where(created_at: Time.current.beginning_of_month..Time.current).average(:number_of_selections)
    @current_week_selection = current_week_total_selection
    @total_selection_today = total_selections_today
    @total_count_today = total_count_today
    @selection_by_editor = editor_selection_data
    @photographer_data = photographer_data
    @photoshoot_by_location = photoshoot_by_location
    @selection_by_customer = selection_by_customer
    @selection_by_branch = selection_by_branch
    @selection_by_cso = selection_by_cso
  end

  def sales
    @total_sales = Sale.where(date: Time.current.beginning_of_month..Time.current).sum(:amount_paid)
    @total_selection = PhotoShoot.where(date: Time.current.beginning_of_month..Time.current).sum(:number_of_selections)
    @total_transaction = Sale.where(date: Time.current.beginning_of_month..Time.current).count(:id)
    @avg_sales = Sale.where(created_at: Time.current.beginning_of_month..Time.current).average(:amount_paid)
    @total_sales_today = total_sales_today
    @total_count_today = total_count_today
    @selection_by_editor = editor_selection_data
    @sale_by_type_of_shoot = sale_by_type_of_shoot
    @sale_type = sale_by_type_of_shoot.map { |type_of_shoot, total_amount| { name: type_of_shoot, y: total_amount } }.to_json
    @sales_by_location_json = sales_by_location_json
    @sale_by_number_of_outfit = sale_by_number_of_outfit.map do |location, total_amount|
      { name: location, y: total_amount }
    end.to_json
    @sales_by_location = sales_by_location
    @selection_by_branch = selection_by_branch
    @selection_by_cso = selection_by_cso
    @sale_by_outfit = sale_by_number_of_outfit
    @sale_total_location = sale_total_location
  end


  private


  def total_selections_today
    start_of_today = Time.current.beginning_of_day
    end_of_today = Time.current.end_of_day
    PhotoShoot.where(date: start_of_today..end_of_today).sum(:number_of_selections)
  end

  def total_sales_today
    start_of_today = Time.current.beginning_of_day
    end_of_today = Time.current.end_of_day
    Sale.where(date: start_of_today..end_of_today).sum(:amount_paid)
  end

  def total_count_today
    start_of_today = Time.current.beginning_of_day
    end_of_today = Time.current.end_of_day
    PhotoShoot.where(date: start_of_today..end_of_today).count(:id)
  end

  def current_week_total_selection
    start_of_week = Time.current.beginning_of_week(:monday)
    end_of_week = Time.current.end_of_week(:monday)
    PhotoShoot.where(date: start_of_week..end_of_week).sum(:number_of_selections)
  end

  def editor_selection_data
    start_of_month = Time.current.beginning_of_month
    @editor_selection_data = PhotoShoot.where(date: start_of_month..Time.current)
                                       .group(:editor)
                                       .order('SUM(number_of_selections) DESC')
                                       .sum(:number_of_selections)
    @chart_data = @editor_selection_data.map { |editor_name, selections| { name: editor_name, y: selections } }.to_json
  end

  def photographer_data
    start_of_month = Time.current.beginning_of_month
    photographer_photo_count = PhotoShoot.where(date: start_of_month..Time.current)
                                         .group(:photographer)
                                         .order('SUM(number_of_selections) DESC')
                                         .count(:id)
    @photographer_chart_data = photographer_photo_count.map { |photographer_name, selections| { name: photographer_name, y: selections } }.to_json
  end

  def photoshoot_by_location
    PhotoShoot.joins(:appointment)
              .group('appointments.location')
              .count
              .map do |location, count|
                { name: location, y: count }
              end.to_json
  end

  def sales_by_location_json
    sales_by_location.map do |location, total_amount|
      { name: location, y: total_amount }
    end.to_json
  end

  def sales_by_location
    start_of_month = Time.current.beginning_of_month
    end_of_today = Time.current.end_of_day
    Sale.where(date: start_of_month..end_of_today)
        .group(:location)
        .sum(:amount_paid)
  end

  def sale_total_location
    Sale.group(:location).sum(:amount_paid)
  end

  def sale_by_type_of_shoot
    start_of_month = Time.current.beginning_of_month
    PhotoShoot.joins(:sale)
              .where(date: start_of_month..Time.current)
              .group(:type_of_shoot)
              .order('SUM(sales.amount_paid) DESC')
              .sum('sales.amount_paid')
  end

  def sale_by_number_of_outfit
    start_of_month = Time.current.beginning_of_month
    PhotoShoot.joins(:sale)
              .where(date: start_of_month..Time.current)
              .group(:number_of_outfits)
              .order('SUM(sales.amount_paid) DESC')
              .sum('sales.amount_paid')
  end

  def selection_by_customer
    PhotoShoot.joins(:appointment)
              .select('appointments.name, SUM(photo_shoots.number_of_selections) as total_selections')
              .group('appointments.name')
              .order('total_selections DESC')
  end

  def selection_by_branch
    PhotoShoot.joins(:appointment)
              .select('appointments.location, SUM(photo_shoots.number_of_selections) as total_selections')
              .group('appointments.location')
              .order('total_selections DESC')
  end

  def selection_by_cso
    PhotoShoot.joins(:customer_service)
              .select('staffs.name AS customer_service_name, SUM(photo_shoots.number_of_selections) AS total_selections')
              .group('staffs.name')
              .order('total_selections DESC')
  end
end
