# app/models/gallery.rb
class Gallery < ApplicationRecord
  belongs_to :appointment
  has_many_attached :photos
  has_one :gallery_mapping, dependent: :nullify

  before_create :generate_share_token

  def webp_variant
    photos.map do |photo|
      photo.variant(resize: "800x600", format: :webp).processed
    end
  end

  # Queue this gallery for upload to Smugmug
  def enqueue_smugmug_upload
    GalleryUploadJob.perform_later(self.id)
  end

  # Check if this gallery has been uploaded to Smugmug
  def smugmug_uploaded?
    gallery_mapping&.completed?
  end

  # Get the Smugmug share URL for this gallery
  def smugmug_share_url
    # Ensure share token is valid first
    if gallery_mapping&.present? && !gallery_mapping.share_token_valid?
      gallery_mapping.generate_share_token
    end

    gallery_mapping&.share_url
  end

  # Generate a new share token for this gallery
  def refresh_smugmug_share_token(expires_in = 30.days)
    return false unless gallery_mapping&.present?
    gallery_mapping.generate_share_token(expires_in)
    gallery_mapping.share_url.present?
  end

  private

  def generate_share_token
    # Generate a unique token for sharing (e.g., 20-character string)
    self.share_token = SecureRandom.hex(10) unless share_token.present?
  end
end
