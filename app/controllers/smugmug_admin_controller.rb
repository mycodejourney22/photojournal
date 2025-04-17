# app/controllers/smugmug_admin_controller.rb
class SmugmugAdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_or_manager
  before_action :set_appointment, only: [:map_gallery, :create_mapping]

  def index
    # List appointments that don't have galleries or mappings
    @unmapped_appointments = Appointment.joins(:photo_shoot)
                                        .left_joins(galleries: :gallery_mapping)
                                        .where(galleries: { id: nil })
                                        .or(
                                          Appointment.joins(:photo_shoot)
                                                  .left_joins(galleries: :gallery_mapping)
                                                  .where(gallery_mappings: { id: nil })
                                        )
                                        .order(start_time: :desc)
                                        .page(params[:page])
                                        .per(20)

    # Count of unmapped appointments
    @unmapped_count = @unmapped_appointments.total_count

    # List of recently mapped galleries for reference
    @recent_mappings = GalleryMapping.includes(gallery: :appointment)
                                    .order(created_at: :desc)
                                    .limit(10)
  end

  def search_appointments
    query = params[:query].to_s.strip

    if query.present?
      @appointments = Appointment.global_search(query)
                                .includes(:galleries)
                                .order(start_time: :desc)
                                .page(params[:page])
                                .per(20)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    else
      redirect_to smugmug_admin_index_path
    end
  end

  def map_gallery
    # If the appointment already has galleries, use those
    @galleries = @appointment.galleries

    # If no galleries, create a default one
    if @galleries.empty?
      @gallery = @appointment.galleries.build(title: "#{@appointment.name}'s Gallery")
    else
      @gallery = @galleries.first
    end

    # Find existing mapping if any
    @existing_mapping = @gallery.gallery_mapping if @gallery.persisted?
  end

  def create_mapping
    @gallery = if params[:gallery_id].present?
                 @appointment.galleries.find(params[:gallery_id])
               else
                 @appointment.galleries.create!(title: params[:gallery_title])
               end

    # Create or update the mapping
    @mapping = @gallery.gallery_mapping || GalleryMapping.new(gallery: @gallery)
    @mapping.assign_attributes(
      smugmug_key: params[:smugmug_key],
      smugmug_url: params[:smugmug_url],
      status: :completed,
      metadata: {
        manual_mapping: true,
        mapped_at: Time.current,
        mapped_by: current_user.email,
        photo_count: params[:photo_count].to_i
      }
    )

    if @mapping.save
      redirect_to smugmug_admin_index_path, notice: "Successfully mapped Smugmug gallery to appointment."
    else
      flash.now[:alert] = "Failed to create mapping: #{@mapping.errors.full_messages.join(', ')}"
      render :map_gallery
    end
  end

  def search_smugmug
    # This endpoint will search Smugmug for galleries that match the given criteria
    # It will be useful when we want to find galleries by name, date, etc.
    query = params[:query].to_s.strip

    if query.present?
      # Use SmugmugService to search for galleries
      smugmug_service = SmugmugService.new
      result = smugmug_service.search_galleries(query)

      @galleries = result[:success] ? result[:galleries] : []

      respond_to do |format|
        format.json { render json: @galleries }
        format.html { render partial: 'smugmug_galleries', locals: { galleries: @galleries } }
      end
    else
      respond_to do |format|
        format.json { render json: [] }
        format.html { render plain: "No search query provided" }
      end
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def require_admin_or_manager
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to root_path, alert: "You don't have permission to access this page"
    end
  end
end
