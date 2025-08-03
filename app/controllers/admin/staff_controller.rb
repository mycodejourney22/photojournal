class Admin::StaffController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin_access
    before_action :set_staff_member, only: [:show, :edit, :update, :destroy, :toggle_active]
  
    def index
      @staff_members = Staff.active.order(:name)
      @staff_member = Staff.new
    end
  
    def show
    end
  
    def new
      @staff_member = Staff.new
    end
  
    def create
      @staff_member = Staff.new(staff_member_params)
      
      if @staff_member.save
        redirect_to admin_staff_members_path, notice: 'Staff member added successfully.'
      else
        @staff_members = Staff.all.order(:name)
        render :index, status: :unprocessable_entity
      end
    end
  
    def edit
    end
  
    def update
      if @staff_member.update(staff_member_params)
        redirect_to admin_staff_members_path, notice: 'Staff member updated successfully.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  
    def destroy
      if @staff_member.sales.exists? || @staff_member.photo_shoots_as_photographer.exists?
        redirect_to admin_staff_members_path, alert: 'Cannot delete staff member with existing records.'
      else
        @staff_member.destroy
        redirect_to admin_staff_members_path, notice: 'Staff member removed successfully.'
      end
    end
  
    def toggle_active
      # Add active column to staff if it doesn't exist
      if @staff_member.respond_to?(:active)
        @staff_member.update(active: !@staff_member.active)
        redirect_to admin_staff_members_path, notice: "Staff member #{@staff_member.active? ? 'activated' : 'deactivated'}."
      else
        redirect_to admin_staff_members_path, alert: 'Toggle functionality not available.'
      end
    end
  
    private
  
    def set_staff_member
      @staff_member = Staff.find(params[:id])
    end
  
    def staff_member_params
      # Only permit fields that exist in your Staff model
      permitted_fields = [:name]
      
      # Add conditional fields based on what exists in your model
      permitted_fields << :role if Staff.column_names.include?('role')
      permitted_fields << :email if Staff.column_names.include?('email')
      permitted_fields << :phone if Staff.column_names.include?('phone')
      permitted_fields << :location if Staff.column_names.include?('location')
      permitted_fields << :active if Staff.column_names.include?('active')
      permitted_fields << :specialization if Staff.column_names.include?('specialization')
      
      params.require(:staff).permit(permitted_fields)
    end
  
    def ensure_admin_access
      unless current_user.admin? || current_user.super_admin?
        redirect_to root_path, alert: 'Access denied.'
      end
    end
end
  