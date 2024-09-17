class GalleriesController < ApplicationController
  def new
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.new
  end

  def show
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.find(params[:id])
  end

  def edit
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.find(params[:id])
  end

  def update
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.find(params[:id])
    if params[:gallery][:photos].present?
      @gallery.photos.attach(params[:gallery][:photos])
    end
    if @gallery.save
      redirect_to appointment_gallery_path(appointment_id: @appointment.id, id: @gallery.id), notice: 'Photos were sucessfully added'
    else
      render :edit
    end
  end

  def index
  end

  def create
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.new(gallery_params)
    @gallery.appointment = @appointment
    if @gallery.save
      redirect_to appointment_gallery_path(appointment_id: @appointment.id, id: @gallery.id)
    else
      render :new, status: :unprocessable_entity
    end
  end




  private

  def gallery_params
    params.require(:gallery).permit(:title, photos:[])
  end
end
