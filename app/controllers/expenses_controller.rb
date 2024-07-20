class ExpensesController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  def new
    authorize Expense
    @expense = Expense.new
  end

  def create
    authorize Expense
    @expense = Expense.new(expense_params)
    @expense.location = determine_location(current_user)
    if @expense.save
      redirect_to expenses_path, notice: 'Expense was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    authorize Expense
    @expenses = policy_scope(Expense).all.order(date: :desc)
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:date, :description, :category, :staff, :amount, :location)
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
