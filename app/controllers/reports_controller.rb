class ReportsController < ApplicationController

    def index
    authorize :report, :index?

    # You can add summary stats here if desired
    # @today_appointments = Appointment.where(start_time: Date.current.all_day).count
    # @pending_photoshoots = PhotoShoot.where(status: ['New', 'Pending']).count
    # @total_customers = Customer.count
  end
end
