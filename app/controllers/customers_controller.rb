class CustomersController < ApplicationController

  def index
    @customers = Customer.all.page(params[:page])
    @customers = Customer.global_search(params[:query]) if params[:query].present?
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

end
