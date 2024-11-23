class Appointment < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :sales, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true
  has_one :photo_shoot
  validates :name, presence: true
  validates :email, presence: true
  validates :location, presence: true
  has_many :galleries
  has_many_attached :customer_pictures
  has_many_attached :photo_inspirations
  after_commit :process_images, on: :create



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

  def formatted_start_time
    start_time.strftime("%A, %d %B %Y") if start_time
  end

  def formatted_time
    start_time.in_time_zone('West Central Africa').strftime("%I:%M %p") if start_time
  end

  private

  def process_images
    images = customer_pictures + photo_inspirations
    images.each do |photo|
      ProcessImageJob.perform_later(photo.id)
    end
  end

end
