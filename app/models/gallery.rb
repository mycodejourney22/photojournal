class Gallery < ApplicationRecord
  belongs_to :appointment
  has_many_attached :photos
end
