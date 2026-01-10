# app/models/training_enrollment.rb
class TrainingEnrollment < ApplicationRecord
  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :program, presence: true, inclusion: { in: %w[essentials mastery] }
  validates :experience, presence: true, inclusion: { in: %w[beginner hobbyist intermediate advanced] }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :essentials, -> { where(program: 'essentials') }
  scope :mastery, -> { where(program: 'mastery') }
  scope :pending, -> { where(status: 'pending') }
  scope :contacted, -> { where(status: 'contacted') }
  scope :enrolled, -> { where(status: 'enrolled') }

  # Status options
  STATUSES = %w[pending contacted enrolled cancelled].freeze

  # Program display names
  PROGRAMS = {
    'essentials' => 'Essentials - ₦150,000',
    'mastery' => 'Complete Mastery - ₦300,000'
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

  def program_name
    PROGRAMS[program] || program
  end

  def experience_level
    EXPERIENCE_LEVELS[experience] || experience
  end
end
