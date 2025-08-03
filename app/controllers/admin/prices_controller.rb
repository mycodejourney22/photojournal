# app/controllers/admin/prices_controller.rb
class Admin::PricesController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin_access
    before_action :set_price, only: [:show, :edit, :update, :destroy, :toggle_active]
  
    def index
      @prices = Price.all.order(:created_at)
      @price = Price.new
    end
  
    def show
    end
  
    def new
      @price = Price.new
    end
  
    def create
      @price = Price.new(price_params)
      
      if @price.save
        redirect_to admin_prices_path, notice: 'Price package created successfully.'
      else
        render :new, status: :unprocessable_entity
      end
    end
  
    def edit
    end
  
    def update
      if @price.update(price_params)
        redirect_to admin_prices_path, notice: 'Price package updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  
    def destroy
      if @price.appointments.exists?
        redirect_to admin_prices_path, alert: 'Cannot delete price package with existing appointments.'
      else
        @price.destroy
        redirect_to admin_prices_path, notice: 'Price package deleted successfully.'
      end
    end
  
    def toggle_active
      if @price.respond_to?(:active)
        @price.update(active: !@price.active)
        redirect_to admin_prices_path, notice: "Price package #{@price.active? ? 'activated' : 'deactivated'}."
      else
        redirect_to admin_prices_path, alert: 'Toggle functionality not available.'
      end
    end
  
    private
  
    def set_price
      @price = Price.find(params[:id])
    end
  
    def price_params
      # Only permit fields that exist in your Price model
      permitted_fields = [:shoot_type, :amount]
      
      # Add conditional fields based on what exists in your model
      permitted_fields << :package_name if Price.column_names.include?('package_name')
      permitted_fields << :duration if Price.column_names.include?('duration')
      permitted_fields << :active if Price.column_names.include?('active')
      permitted_fields << :description if Price.column_names.include?('description')
      
      params.require(:price).permit(permitted_fields)
    end
  
    def ensure_admin_access
      unless current_user.admin? || current_user.super_admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end
end