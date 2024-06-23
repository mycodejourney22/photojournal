class SalesController < ApplicationController
  def index
    @sales = Sale.all
  end

  def new
    @sale = Sale.new
  end


  def create
    @sale = Sale.new(sale_params)
    @sale.location = determine_location(current_user)

    if @sale.save
      redirect_to sales_path, notice: 'Sale was successfully created.'
    else
      render :new
    end
  end

  def upfront
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
