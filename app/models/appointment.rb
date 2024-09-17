class Appointment < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :sales, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true
  has_one :photo_shoot
  validates :name, presence: true
  validates :email, presence: true
  validates :location, presence: true
  has_many :galleries

  include PgSearch::Model
  pg_search_scope :global_search,
  against: [ :name, :email],
    using: {
      tsearch: { prefix: true }
    }

  def mapped_location
    case location.downcase
    when /ikeja/
      'Ikeja'
    when /surulere/
      'Surulere'
    when /ajah/, /ilaje/
      'Ajah'
    else
      'unknown'
    end
  end

  def has_galleries?
    galleries.exists?
  end
end
