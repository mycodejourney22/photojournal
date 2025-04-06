require 'csv'

class CustomersController < ApplicationController

  before_action :set_customer, only: [ :generate_referral]


  def index
    @customers = Customer.all
    @customers = Customer.global_search(params[:query]) if params[:query].present?
    @customers = @customers.page(params[:page])
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "table", locals: {customers: @customers}, formats: [:html] }
    end
  end

  def export
    @customers = Customer.all

    # Apply any filters if needed
    @customers = @customers.global_search(params[:query]) if params[:query].present?

    respond_to do |format|
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=customers_#{Date.today.strftime('%Y%m%d')}.csv"

        # Generate CSV
        csv_data = CSV.generate do |csv|
          # Header row
          csv << ['Name', 'Email', 'Phone Number', 'Total Visits', 'Total Spent', 'Referral Credits', 'Last Visit', 'Created At']

          # Data rows
          @customers.each do |customer|
            csv << [
              customer.name,
              customer.email,
              customer.phone_number,
              customer.visits_count,
              customer.sales.sum(:amount_paid),
              customer.credits,
              customer.sales.maximum(:date)&.strftime("%Y-%m-%d"),
              customer.created_at.strftime("%Y-%m-%d")
            ]
          end
        end

        # Send data to browser
        send_data csv_data, type: 'text/csv', filename: "customers_#{Date.today.strftime('%Y%m%d')}.csv"
      end
    end
  end

  def show
    @customer = Customer.find(params[:id])
    phone_number = @customer.phone_number
    @appointments = Appointment.joins(:questions)
                               .where(questions: { question: 'Phone number' })
                               .where("REGEXP_REPLACE(questions.answer, '\\D', '', 'g') ~ '^234' AND '0' || SUBSTRING(REGEXP_REPLACE(questions.answer, '\\D', '', 'g') FROM 4) = ? OR REGEXP_REPLACE(questions.answer, '\\D', '', 'g') = ?", phone_number, phone_number)
    @appointments_with_galleries = @appointments.select(&:has_galleries?)
  end

  def all_galleries
    @customer = Customer.find(params[:id])
    phone_number = @customer.phone_number
    @appointments = Appointment.joins(:questions)
                               .where(questions: { question: 'Phone number' })
                               .where("REGEXP_REPLACE(questions.answer, '\\D', '', 'g') ~ '^234' AND '0' || SUBSTRING(REGEXP_REPLACE(questions.answer, '\\D', '', 'g') FROM 4) = ? OR REGEXP_REPLACE(questions.answer, '\\D', '', 'g') = ?", phone_number, phone_number)
                               .includes(:galleries)
    @appointments_with_galleries = @appointments.select(&:has_galleries?)
  end

  def generate_referral
    # Generate a new referral
    referral = @customer.generate_referral

    if referral.persisted?
      # Send email with the new referral code
      ReferralMailer.invitation_email(referral).deliver_later

      # Redirect back with success message
      redirect_to customer_path(@customer), notice: "New referral code generated and sent to customer."
    else
      # Handle error
      redirect_to customer_path(@customer), alert: "Could not generate referral code. Please try again."
    end
  end


  def sync_all_to_brevo
    # Authorization check if using Pundit
    # authorize Customer if respond_to?(:authorize)

    # Queue the background job to sync all customers
    BrevoSyncAllJob.perform_later

    # Notify the user and redirect back
    redirect_to customers_path, notice: 'Syncing all customers to Brevo has been started. This process may take some time.'
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end


  def sync_with_brevo
    # Skip if no email provided or in test environment
    return unless email.present? && !Rails.env.test?

    # Sync in background to avoid slowing down the request
    BrevoSyncJob.perform_later(self.id)
  end
end
