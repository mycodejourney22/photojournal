class Appointment < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :sales, dependent: :destroy
  accepts_nested_attributes_for :questions, allow_destroy: true
  has_one :photo_shoot
  validates :name, presence: true
  validates :email, presence: true
  validates :location, presence: true
  has_many :galleries
  has_many :refund_requests
  has_many_attached :customer_pictures
  has_many_attached :photo_inspirations
  after_commit :process_images, on: :create
  belongs_to :price, optional: true # This assumes a Price model exists
  before_validation :set_defaults
  before_validation :normalize_location


  scope :available_for_booking, -> { where(no_show: false, status: true) }
  scope :for_today, -> { where(start_time: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day) }
  scope :upcoming, -> { where('start_time > ?', Time.zone.now.end_of_day).available_for_booking }
  scope :past, -> { where(start_time: 14.days.ago.beginning_of_day..Time.zone.now.beginning_of_day)
                         .order(start_time: :desc) }
  scope :today, -> { for_today.available_for_booking }

  def status_object
    @status_object ||= AppointmentStatus.new(self)
  end

  def available_for_booking?
    !no_show && status
  end

  STUDIO_NUMBERS = {
    'ajah' => '08144985074',
    'surulere' => '07048891715',
    'ikeja' => '08090151168'
  }.freeze



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
      self.price ||= Price.find(price_id) if price_id.present?
    end
  end

  def schedule_policy_email
    SendPolicyEmailJob.set(wait: 1.minute).perform_later(id)
  end

  def schedule_reminder_email
    # Calculate the reminder times
    reminder_2_hours = start_time - 2.hours
    reminder_24_hours = start_time - 24.hours

    # Schedule the 2-hour reminder only if it's in the future
    if reminder_2_hours > Time.current
      ReminderEmailJob.set(wait_until: reminder_2_hours).perform_later(id)
    end

    # Schedule the 24-hour reminder only if it's in the future
    if reminder_24_hours > Time.current
      ReminderEmailJob.set(wait_until: reminder_24_hours).perform_later(id)
    end
  end


  private

  def process_images
    images = customer_pictures + photo_inspirations
    images.each do |photo|
      ProcessImageJob.perform_later(photo.id)
    end
  end

  def normalize_location
    return unless location.present?

    case location.downcase
    when /ikeja/
      self.location = "Ikeja"
    when /surulere/
      self.location = "Surulere"
    when /ajah/, /ilaje/
      self.location = "Ajah"
    else
      # Keep the original location
      self.location = location
    end
  end
end
