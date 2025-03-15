# require 'pry'
class SalesController < ApplicationController
  include PhoneNumberNormalizer
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  before_action :set_appointment, only: [:new, :create]

  def index
    authorize Sale
    @sales = policy_scope(Sale).all.order(date: :desc)
    @sales = Sale.global_search(params[:query]) if params[:query].present?
    @sales = @sales.page(params[:page])
  end

  def new
    authorize Sale
    @sale = @appointment ? @appointment.sales.build : Sale.new
  end

  def create
    authorize Sale
    @sale = build_sale
    assign_customer_to_sale(@sale)

    @sale.location = determine_location(current_user)

    if @sale.save
      redirect_to_success
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize Sale
    @sale = Sale.find(params[:id])
  end

  def update
    @sale = Sale.find(params[:id])
    authorize @sale
    if @sale.update(sale_params)
      redirect_to sales_path, notice: 'Sale was successfully updated.'
    else
      render :edit
    end
  end

  def upfront
    authorize Sale
    @sales = Sale.where(payment_type: "Part payment")
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "table", locals: {sales: @sales}, formats: [:html] }
    end
  end

  def show
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id]) if params[:appointment_id]
  end

  def sale_params
    params.require(:sale).permit(:void, :void_reason,:date, :amount_paid, :payment_method, :payment_type, :appointment_id,:staff_id,
      :customer_name, :customer_phone_number, :customer_service_officer_name, :product_service_name)
  end

  def determine_location(user)
    case user.role
    when 'admin'
      'general'
    when 'ajah'
      'ajah'
    when 'ikeja'
      'ikeja'
    when 'surulere'
      'surulere'
    else
      'unknown'
    end
  end

  def build_sale
    if @appointment
      sale = @appointment.sales.build(sale_params)
      sale.customer_name = @appointment.name
      sale
    else
      Sale.new(sale_params)
    end
  end

  def assign_customer_to_sale(sale)
    phone_number = extract_phone_number_from_appointment(@appointment) if @appointment
    customer = find_or_create_customer(phone_number)

    sale.customer_id = customer.id if customer.present?
  end

  def find_or_create_customer(phone_number)
    normalized_phone_number = phone_number ? normalize_phone_number(phone_number) : phone_number
    customer = Customer.find_by(phone_number: @appointment ? normalized_phone_number : @sale.customer_phone_number)

    unless customer && customer.phone_number.present?
      if @appointment.present?
        customer = Customer.new(name: @appointment.name, phone_number: normalized_phone_number)
      else
        customer = Customer.new(name: @sale.customer_name, phone_number: @sale.customer_phone_number)
      end
      if customer.save
        customer
      else
        Rails.logger.error "Failed to create customer: #{customer.errors.full_messages.join(', ')}"
        return nil
      end
    end
    customer
  end

  def redirect_to_success
    if @sale.appointment
      redirect_to @sale.appointment, notice: 'Sale was successfully created.'
    else
      redirect_to sales_path, notice: 'Sale was successfully created.'
    end
  end

  def extract_phone_number_from_appointment(appointment)
    appointment.questions.find { |q| q.question == 'Phone number' }.answer
  end

  # def normalize_phone_number(phone_number)
  #   # Remove non-numeric characters
  #   phone_number = phone_number.gsub(/\D/, "") if phone_number

  #   # Check if phone number starts with the country code +234 or 234
  #   if phone_number.start_with?("234")
  #     # Replace '234' with '0'
  #     phone_number.sub("234", "0")
  #   elsif phone_number.start_with?("+234")
  #     # Remove the '+' and replace '234' with '0'
  #     phone_number.sub("+234", "0")
  #   end
  #   phone_number
  # end

  def create_customer(customer, sale)
      customer.name = sale.customer_name
      # customer.email = sale.email
      customer.phone_number = sale.customer_phone_number
      customer.save
  end


end
