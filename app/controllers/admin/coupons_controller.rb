# app/controllers/admin/coupons_controller.rb
class Admin::CouponsController < ApplicationController
    before_action :set_coupon, only: [:show, :edit, :update, :destroy, :toggle_status]
    after_action :verify_authorized
  
    def index
      authorize Coupon
      @coupons = policy_scope(Coupon).order(created_at: :desc)
      
      # Filter by status if requested
      if params[:status].present?
        @coupons = @coupons.where(status: params[:status])
      end
      
      # Filter by coupon type if requested
      if params[:coupon_type].present?
        @coupons = @coupons.where(coupon_type: params[:coupon_type])
      end
      
      # Search by code or description
      if params[:search].present?
        @coupons = @coupons.where("code ILIKE ? OR description ILIKE ?", 
                                  "%#{params[:search]}%", "%#{params[:search]}%")
      end
      
      @coupons = @coupons.page(params[:page])
    end
  
    def show
      authorize @coupon
    end
  
    def new
      @coupon = Coupon.new
      authorize @coupon
    end
  
    def create
      @coupon = Coupon.new(coupon_params)
      authorize @coupon
  
      if @coupon.save
        redirect_to admin_coupons_path, notice: 'Coupon was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end
  
    def edit
      authorize @coupon
    end
  
    def update
      authorize @coupon
      
      if @coupon.update(coupon_params)
        redirect_to admin_coupon_path(@coupon), notice: 'Coupon was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  
    def destroy
      authorize @coupon
      @coupon.destroy
      redirect_to admin_coupons_path, notice: 'Coupon was successfully deleted.'
    end
  
    def toggle_status
      authorize @coupon
      
      new_status = @coupon.active? ? 'inactive' : 'active'
      @coupon.update(status: new_status)
      
      redirect_to admin_coupons_path, notice: "Coupon #{new_status == 'active' ? 'activated' : 'deactivated'} successfully."
    end
  
    private
  
    def set_coupon
      @coupon = Coupon.find(params[:id])
    end
  
    def coupon_params
      params.require(:coupon).permit(:code, :coupon_type, :description, :discount_amount, 
                                    :discount_percentage, :max_uses, :expires_at, :status, 
                                    :customer_restrictions, :campaign_notes, :minimum_amount)
    end
end