class GadgetsController < ApplicationController
  def index
    @gadgets = Gadget.all.order(date: :desc).page(params[:page])
  end

  def new
    @gadget = Gadget.new
  end

  def show
  end

  def create
    @gadget = Gadget.new(gadget_params)
    if @gadget.save
      redirect_to gadgets_path, notice: 'Gadget was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def gadget_params
    params.require(:gadget).permit(:name, :location, :descriptions, :date, :amount, :quantity)
  end
end
