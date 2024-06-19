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


  private


  def total_selections_today
    start_of_today = Time.current.beginning_of_day
    end_of_today = Time.current.end_of_day
    PhotoShoot.where(date: start_of_today..end_of_today).sum(:number_of_selections)
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
