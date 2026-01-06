class Admin::SetupController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin_access

    def index
      @stats = {
        prices: Price.where(still_valid: true).count,
        staff_members: Staff.active.count,
        studios: Studio.active.count,
        users: User.count,
        active_appointments: Appointment.where(status: true).count,
        total_sales: Sale.count,
        gadgets: Gadget.count
      }
    end

    private

    def ensure_admin_access
      unless current_user.admin? || current_user.super_admin?
        redirect_to root_path, alert: 'Access denied. Admin privileges required.'
      end
    end
end
