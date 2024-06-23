class SalesController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  def index
    authorize Sale
    @sales = policy_scope(Sale).all.order(created_at: :desc)
  end

  def new
    authorize Sale
    @sale = Sale.new
  end


  def create
    authorize Sale
    @sale = Sale.new(sale_params)
    @sale.location = determine_location(current_user)

    if @sale.save
      redirect_to sales_path, notice: 'Sale was successfully created.'
    else
      render :new
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

  def sale_params
    params.require(:sale).permit(:date, :amount_paid, :payment_method, :payment_type, :customer_name, :customer_phone_number, :customer_service_officer_name, :product_service_name)
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
