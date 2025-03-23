# app/controllers/smugmug_dashboard_controller.rb
class SmugmugDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_or_manager

  def index
    @pending_uploads = GalleryMapping.where(status: :pending).includes(:gallery).order(created_at: :desc)
    @processing_uploads = GalleryMapping.where(status: :processing).includes(:gallery).order(created_at: :desc)
    @recent_uploads = GalleryMapping.where(status: :completed).includes(:gallery).order(created_at: :desc).limit(20)
    @failed_uploads = GalleryMapping.where(status: :failed).includes(:gallery).order(created_at: :desc)

    # Summary statistics
    @total_galleries = Gallery.count
    @total_uploaded = GalleryMapping.where(status: :completed).count
    @upload_percentage = @total_galleries > 0 ? (@total_uploaded.to_f / @total_galleries * 100).round(1) : 0

    # Total photos uploaded
    @total_photos = ActiveStorage::Attachment.where(record_type: 'Gallery').count

    # Most viewed galleries
    @most_viewed = GalleryMapping.where(status: :completed)
                                .order(views_count: :desc)
                                .limit(5)
                                .includes(:gallery)

    # Recent activity
    @recent_activity = GalleryMapping.order(updated_at: :desc).limit(10).includes(:gallery)
  end

  def retry_upload
    mapping = GalleryMapping.find(params[:id])
    mapping.update(status: :pending, error_message: nil)

    # Queue the job
    if mapping.gallery.present?
      mapping.gallery.enqueue_smugmug_upload
      redirect_to smugmug_dashboard_path, notice: 'Upload has been queued for retry'
    else
      redirect_to smugmug_dashboard_path, alert: 'Unable to retry upload: gallery not found'
    end
  end

  def refresh_token
    mapping = GalleryMapping.find(params[:id])

    if mapping.present? && mapping.gallery.present?
      if mapping.gallery.refresh_smugmug_share_token
        redirect_to smugmug_dashboard_path, notice: 'Share token has been refreshed'
      else
        redirect_to smugmug_dashboard_path, alert: 'Unable to refresh share token'
      end
    else
      redirect_to smugmug_dashboard_path, alert: 'Gallery mapping or gallery not found'
    end
  end

  private

  def require_admin_or_manager
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to root_path, alert: "You don't have permission to access this page"
    end
  end
end
