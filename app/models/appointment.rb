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
  belongs_to :price, optional: true # This assumes a Price model exists
  before_validation :set_defaults



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

  def set_defaults(user = nil)
    if user.present?
      self.channel ||= "walk in"
    else
      self.channel ||= "online"
      self.price ||= Price.find(price_id) if price_id.present? # Assign price from the selected price instance
    end
  end

  def schedule_policy_email
    SendPolicyEmailJob.set(wait: 1.minute).perform_later(id)
  end

  def schedule_reminder_email
    ReminderEmailJob.set(wait_until: @appointment.start_time - 2.hours).perform_later(@appointment) if @appointment.id.present?
    ReminderEmailJob.set(wait_until: @appointment.start_time - 24.hours).perform_later(@appointment) if @appointment.id.present?
  end

  private

  def process_images
    images = customer_pictures + photo_inspirations
    images.each do |photo|
      ProcessImageJob.perform_later(photo.id)
    end
  end



end
