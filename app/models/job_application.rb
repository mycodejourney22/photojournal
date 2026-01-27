# app/models/job_application.rb
class JobApplication < ApplicationRecord
  has_one_attached :cv
  has_many_attached :portfolio_files

  POSITIONS = [
    'Lead Photographer',
    'Assistant Photographer',
    'Photo Retoucher',
    'Videographer',
    'Studio Manager',
    'Creative Director',
    'Customer Service'
  ].freeze

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :position, presence: true, inclusion: { in: POSITIONS }
  validates :motivation, presence: true
  validates :cv, presence: true

  before_create :generate_reference_number

  scope :recent, -> { order(created_at: :desc) }
  scope :by_position, ->(position) { where(position: position) }

  def formatted_created_at
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end

  private

  def generate_reference_number
    self.reference_number = "APP-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end
end
