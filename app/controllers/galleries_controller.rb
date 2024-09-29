class GalleriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:public_show, :download]

  def new
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.new
  end

  def show
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.includes(photos_attachments: :blob).find(params[:id])
  end

  def public_show
    @gallery = Gallery.includes(photos_attachments: :blob).find_by(share_token: params[:share_token])
    @appointment = @gallery.appointment if @gallery
    if @gallery
      render :public_show # This will use a different view for the public gallery
    else
      redirect_to root_path, alert: 'Gallery not found'
    end
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

  def download
    photo = ActiveStorage::Attachment.find(params[:id]) # find the attachment by id
    send_data photo.download, filename: photo.filename.to_s, type: photo.content_type, disposition: 'attachment'
  end

  def send_gallery
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.find(params[:gallery_id])
    # @gallery_url = "http://localhost:3000/galleries/public/#{@gallery.share_token}"
    @gallery_url = gallery_public_url(@gallery.share_token, host: request.base_url)

    # Send the email
    PhotoMailer.send_gallery(@appointment, @gallery_url, @gallery).deliver_later

    redirect_to appointment_gallery_path(@appointment, @gallery), notice: 'Gallery link sent to customer!'
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
