class PricesController < ApplicationController
  def new
    @price = Price.new
  end

  def index
    @prices = Price.where(still_valid: true)
  end

  def create
    @price = Price.new(price_params)
    if @price.save
      redirect_to prices_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @price = Price.find(params[:id])
  end

  def destroy
    @price = Price.find(params[:id])

    if @price.destroy
      respond_to do |format|
        format.html { redirect_to prices_path, notice: 'Price was successfully deleted.' }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to prices_path, alert: 'Unable to delete price.' }
        format.json { render json: @price.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @price = Price.find(params[:id])
    if @price.update(price_params)
      redirect_to prices_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def price_params
    params.require(:price).permit(:amount, :description, :discount, :duration,
                                  :name, :included, :still_valid, :period, :photo)
  end
end
