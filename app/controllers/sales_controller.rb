class SalesController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  before_action :set_appointment, only: [:new, :create]

  def index
    authorize Sale
    @sales = policy_scope(Sale).all.order(date: :desc)
    @sales = Sale.global_search(params[:query]) if params[:query].present?
  end

  def new
    authorize Sale
    @sale = @appointment ? @appointment.sales.build : Sale.new
  end

  def create
    authorize Sale
    if @appointment
      @sale = @appointment.sales.build(sale_params)
      @sale.customer_name = @appointment.name
    else
      @sale = Sale.new(sale_params)
    end
    @sale.location = determine_location(current_user)
    # raise
    if @sale.save
      if @sale.appointment
        redirect_to @sale.appointment, notice: 'Sale was successfully created.'
      else
        redirect_to sales_path, notice: 'Sale was successfully created.'
      end
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
    params.require(:sale).permit(:date, :amount_paid, :payment_method, :payment_type, :appointment_id,:staff_id,
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

end
