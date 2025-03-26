# app/controllers/galleries_controller.rb
class GalleriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:public_show, :download, :smugmug_redirect]
  before_action :set_gallery, except: [:new, :create, :index, :public_show, :smugmug_redirect, :add_to_existing, :upload_to_existing]
  before_action :set_appointment, only: [:new, :create, :show, :edit, :update , :add_to_existing, :upload_to_existing]

  def new
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.new
  end

  def show
    @appointment = Appointment.find(params[:appointment_id])
    @editor_name = @appointment.photo_shoot.editor.name if @appointment.photo_shoot
    @photographer_name = @appointment.photo_shoot.photographer.name if @appointment.photo_shoot
    @gallery = Gallery.includes(photos_attachments: :blob).find(params[:id])

    # Register a view of this gallery
    @gallery.gallery_mapping&.register_view! if @gallery.gallery_mapping.present?
  end

  def stream_photo
    @gallery = Gallery.find(params[:id])
    @photo = @gallery.photos.find(params[:photo_id])

    # Stream the photo using `send_data`
    photo_blob = @photo.download

    send_data photo_blob, type: @photo.content_type, disposition: 'inline', buffer_size: 64.kilobytes, cache_control: 'public, max-age=31536000'
  end

  def public_show
    @gallery = Gallery.includes(photos_attachments: :blob).find_by(share_token: params[:share_token])
    @appointment = @gallery.appointment if @gallery
    if @gallery
      # Register a view of this gallery
      @gallery.gallery_mapping&.register_view! if @gallery.gallery_mapping.present?
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
      # Queue Smugmug upload if photos were added
      @gallery.enqueue_smugmug_upload if params[:gallery][:photos].present?

      redirect_to appointment_path(@appointment), notice: 'Photos were successfully added'
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

    # Try to use Smugmug URL if available
    if @gallery.smugmug_uploaded? && @gallery.smugmug_share_url.present?
      @gallery_url = @gallery.smugmug_share_url
    else
      # Fall back to the application's gallery URL
      @gallery_url = gallery_public_url(@gallery.share_token, host: request.base_url)

      # Optionally, we could queue Smugmug upload if it hasn't been done yet
      unless @gallery.smugmug_uploaded?
        @gallery.enqueue_smugmug_upload
        flash[:notice] = "Gallery is being uploaded to Smugmug. An email with the updated link will be sent when processing is complete."
      end
    end

    # Send the email
    PhotoMailer.send_gallery(@appointment, @gallery_url, @gallery).deliver_later

    redirect_to appointment_gallery_path(@appointment, @gallery), notice: 'Gallery link sent to customer!'
  end

  def index
  end

  def add_to_existing
    # @galleries = @appointment.galleries.order(created_at: :desc)
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = @appointment.galleries.find(params[:id])
    # raise
  end

  # Add this action to handle uploading to an existing gallery
  def upload_to_existing

    if params[:id].present?
      # Add to existing gallery
      @gallery = Gallery.find(params[:id])

      if params[:photos].present?
        @gallery.photos.attach(params[:photos])

        # Update metadata to reflect the new photos
        if @gallery.gallery_mapping&.present?
          current_metadata = @gallery.gallery_mapping.metadata || {}
          newly_attached_count = params[:photos].is_a?(Array) ?
                                 params[:photos].size :
                                 (params[:photos].respond_to?(:count) ? params[:photos].count : 1)
          updated_metadata = current_metadata.merge({
            "photo_count" => (current_metadata["photo_count"].to_i + newly_attached_count),
            "last_upload" => Time.current,
            "failed_uploads" => (current_metadata["failed_uploads"].to_i || 0),
            "successful_uploads" => (current_metadata["successful_uploads"].to_i + newly_attached_count),
            "upload_details" => {
              "failed" => current_metadata.dig("upload_details", "failed") || [],
              # Append to existing success entries rather than replacing
              "success" => (current_metadata.dig("upload_details", "success") || [])
            },
            "photo_filenames" => (current_metadata["photo_filenames"] || []) +
                                 @gallery.photos.attachments.last(newly_attached_count).map { |a| a.blob.filename.to_s }
          })

          @gallery.gallery_mapping.update(
            status: :pending,
            error_message: nil,
            metadata: updated_metadata
          )
        end

        # Queue SmugMug upload
        @gallery.enqueue_smugmug_upload

        redirect_to appointment_path(@appointment), notice: "Photos were successfully added to the gallery."
      else
        redirect_to add_to_existing_appointment_gallery_path(@appointment, @appointment.galleries.first), alert: "No photos were selected."
      end
    else
      # No gallery selected
      redirect_to add_to_existing_appointment_galleries_path(@appointment), alert: "Please select a gallery to add photos to."
    end
  end


  def create
    @appointment = Appointment.find(params[:appointment_id])
    @gallery = Gallery.new(gallery_params)
    @gallery.appointment = @appointment

    if @gallery.save
      # Queue Smugmug upload if photos were attached
      @gallery.enqueue_smugmug_upload if @gallery.photos.attached?

      redirect_to appointment_path(@appointment), notice: "Gallery was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # Handle Smugmug upload manually
  def upload_to_smugmug
    @gallery.enqueue_smugmug_upload
    redirect_to appointment_gallery_path(@appointment, @gallery), notice: 'Gallery upload to Smugmug has been queued. You will be notified when complete.'
  end

  # Redirect to Smugmug gallery view
  def smugmug_redirect
    @gallery = Gallery.find(params[:id])

    if @gallery.smugmug_uploaded? && @gallery.gallery_mapping.smugmug_url.present?
      redirect_to @gallery.gallery_mapping.smugmug_url, allow_other_host: true
    else
      redirect_to appointment_gallery_path(@gallery.appointment, @gallery), alert: 'Smugmug gallery not available yet'
    end
  end

  private

  def set_gallery
    @gallery = Gallery.find(params[:id])
  end

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  def gallery_params
    params.require(:gallery).permit(:title, photos:[])
  end
end
