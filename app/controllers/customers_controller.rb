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

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

end
