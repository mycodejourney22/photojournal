# app/models/gallery_mapping.rb
class GalleryMapping < ApplicationRecord
  belongs_to :gallery
  belongs_to :customer, optional: true

  # Only validate smugmug_key when status is completed AND it's a new record or the key changed
  validates :smugmug_key, presence: true, if: -> { completed? }
  validates :smugmug_key, uniqueness: true, if: -> { completed? && (new_record? || smugmug_key_changed?) }
  validates :gallery_id, presence: true

  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  scope :completed, -> { where(status: :completed) }
  scope :for_customer, ->(customer) { where(customer_id: customer.id) }
  scope :recent, -> { order(created_at: :desc) }

  # Check if the gallery has already been uploaded to the same smugmug location
  def self.exists_for_gallery_at_location?(gallery_id, smugmug_url)
    where(gallery_id: gallery_id, smugmug_url: smugmug_url).exists?
  end

  # Find existing mapping by gallery and URL
  def self.find_by_gallery_and_url(gallery_id, smugmug_url)
    where(gallery_id: gallery_id, smugmug_url: smugmug_url).first
  end

  # Generate and save a share token for this gallery
  # def generate_share_token(expires_in = 30.days)
  #   # Skip if we already have a valid token
  #   return self if share_token.present? && share_token_expires_at.present? && share_token_expires_at > Time.current

  #   result = SmugmugService.new.create_share_token(smugmug_key, expires_in)

  #   if result[:success]
  #     update(
  #       share_token: result[:token],
  #       share_url: result[:url],
  #       share_token_expires_at: result[:expires_at]
  #     )
  #   else
  #     Rails.logger.error("Failed to generate share token: #{result[:error]}")
  #   end

  #   self
  # end

  # Check if share token is valid (not expired)
  def share_token_valid?
    share_token.present? && share_token_expires_at.present? && share_token_expires_at > Time.current
  end

  # Increment view count
  def register_view!
    increment!(:views_count)
    touch(:last_accessed_at)
  end

  def sync_photo_count_with_gallery!
    if gallery.present? && completed?
      actual_photo_count = gallery.photos.count
      current_metadata = self.metadata || {}

      # Update metadata with the correct photo count
      updated_metadata = current_metadata.merge({
        "photo_count" => actual_photo_count,
        "successful_uploads" => actual_photo_count
      })

      self.update(metadata: updated_metadata)
    end
  end
end
