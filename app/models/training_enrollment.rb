# # app/models/training_enrollment.rb
# class TrainingEnrollment < ApplicationRecord
#   # Validations
#   validates :first_name, presence: true
#   validates :last_name, presence: true
#   validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
#   validates :phone, presence: true
#   validates :program, presence: true, inclusion: { in: %w[essentials mastery] }
#   validates :experience, presence: true, inclusion: { in: %w[beginner hobbyist intermediate advanced] }

#   # Scopes
#   scope :recent, -> { order(created_at: :desc) }
#   scope :essentials, -> { where(program: 'essentials') }
#   scope :mastery, -> { where(program: 'mastery') }
#   scope :pending, -> { where(status: 'pending') }
#   scope :contacted, -> { where(status: 'contacted') }
#   scope :enrolled, -> { where(status: 'enrolled') }

#   # Status options
#   STATUSES = %w[pending contacted enrolled cancelled].freeze

#   # Program display names
#   PROGRAMS = {
#     'essentials' => 'Essentials - ₦150,000',
#     'mastery' => 'Complete Mastery - ₦300,000'
#   }.freeze

#   # Experience level display names
#   EXPERIENCE_LEVELS = {
#     'beginner' => 'Complete Beginner',
#     'hobbyist' => 'Hobbyist / Enthusiast',
#     'intermediate' => 'Intermediate',
#     'advanced' => 'Advanced (looking to specialize)'
#   }.freeze

#   def full_name
#     "#{first_name} #{last_name}"
#   end

#   def program_name
#     PROGRAMS[program] || program
#   end

#   def experience_level
#     EXPERIENCE_LEVELS[experience] || experience
#   end
# end
# app/models/training_enrollment.rb
class TrainingEnrollment < ApplicationRecord
  include PhoneNumberNormalizer

  before_validation :normalize_phone_number_field
  before_create :generate_uuid

  belongs_to :customer, optional: true
  has_many :sales, dependent: :nullify

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :program, presence: true, inclusion: { in: %w[essentials mastery] }
  validates :experience, presence: true, inclusion: { in: %w[beginner hobbyist intermediate advanced] }
  validates :uuid, uniqueness: true, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :essentials, -> { where(program: 'essentials') }
  scope :mastery, -> { where(program: 'mastery') }
  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(payment_status: true) }
  scope :unpaid, -> { where(payment_status: false) }
  scope :contacted, -> { where(status: 'contacted') }
  scope :enrolled, -> { where(status: 'enrolled') }

  # Status options
  STATUSES = %w[pending contacted enrolled cancelled].freeze

  # Program details with prices (in Naira)
  PROGRAMS = {
    # 'essentials' => { name: 'Essentials', price: 150_000, description: 'Photography Fundamentals' },
    'mastery' => { name: 'Complete Mastery', price: 300_000, description: 'Photography + Full Editing Suite' }
  }.freeze

  # Experience level display names
  EXPERIENCE_LEVELS = {
    'beginner' => 'Complete Beginner',
    'hobbyist' => 'Hobbyist / Enthusiast',
    'intermediate' => 'Intermediate',
    'advanced' => 'Advanced (looking to specialize)'
  }.freeze

  def full_name
    "#{first_name} #{last_name}"
  end

  def program_details
    PROGRAMS[program] || { name: program, price: 0, description: '' }
  end

  def program_name
    program_details[:name]
  end

  def program_price
    program_details[:price]
  end

  def program_name_with_price
    "#{program_name} - ₦#{program_price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def experience_level
    EXPERIENCE_LEVELS[experience] || experience
  end

  def paid?
    payment_status == true
  end

  def mark_as_paid!
    update!(payment_status: true, paid_at: Time.current)
  end

  private

  def generate_uuid
    self.uuid = SecureRandom.uuid if uuid.blank?
  end

  def normalize_phone_number_field
    self.phone = normalize_phone_number(phone) if phone.present?
  end
end
