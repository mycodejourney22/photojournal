class Gallery < ApplicationRecord
  belongs_to :appointment
  has_many_attached :photos

  def webp_variant
    photos.map do |photo|
      photo.variant(resize: "800x600", format: :webp).processed
    end
  end
end
