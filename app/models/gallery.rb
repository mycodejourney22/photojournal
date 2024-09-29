class Gallery < ApplicationRecord
  belongs_to :appointment
  has_many_attached :photos
  before_create :generate_share_token

  def webp_variant
    photos.map do |photo|
      photo.variant(resize: "800x600", format: :webp).processed
    end
  end

  private

  def generate_share_token
    # Generate a unique token for sharing (e.g., 20-character string)
    self.share_token = SecureRandom.hex(10) unless share_token.present?
  end
end
