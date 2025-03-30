# app/models/refund_request.rb
class RefundRequest < ApplicationRecord
  belongs_to :appointment

  # Status states for refund requests
  enum status: {
    pending: 0,    # Initial state when customer submits request
    approved: 1,   # Refund has been approved
    declined: 2,   # Refund has been declined
    processed: 3   # Refund has been processed (money sent to customer)
  }

  # Reasons for refund
  REASONS = [
    'Scheduling conflict',
    'Unsatisfied with service',
    'Change of mind',
    'Financial constraints',
    'Medical emergency',
    'Other'
  ].freeze

  # Validation
  validates :appointment_id, presence: true
  validates :status, presence: true
  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :refund_amount, presence: true, numericality: { greater_than: 0 }
  validates :account_name, presence: true
  validates :account_number, presence: true, format: { with: /\A\d{10}\z/, message: "must be 10 digits" }
  validates :bank_name, presence: true

  # Custom validation to check if amount exceeds what was paid
  validate :refund_amount_not_exceeding_payment

  # Set default status if not specified
  after_initialize :set_defaults, if: :new_record?

  # Callback after status changes to approved
  after_save :create_negative_sale, if: -> { saved_change_to_status? && status == "approved" }

  # Audit who processed the request
  belongs_to :processed_by, class_name: 'User', foreign_key: 'processed_by_id', optional: true

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }
  scope :declined, -> { where(status: :declined) }
  scope :processed, -> { where(status: :processed) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def set_defaults
    self.status ||= :pending
  end

  def refund_amount_not_exceeding_payment
    return unless appointment && refund_amount

    total_paid = appointment.sales.where(void: false).where("amount_paid > 0").sum(:amount_paid)

    if refund_amount > total_paid
      errors.add(:refund_amount, "cannot exceed the total amount paid (₦#{total_paid})")
    end
  end

  def create_negative_sale
    return unless status == "approved"

    # Find a staff member to attribute the refund to
    staff = Staff.find_by(name: "Digital") || Staff.first

    # Create a negative sale entry
    Sale.create!(
      appointment_id: appointment_id,
      date: Date.current,
      amount_paid: -refund_amount, # Negative amount for refund
      customer_name: appointment.name,
      customer_phone_number: extract_phone_number_from_appointment,
      location: appointment.location,
      payment_method: "Refund",
      payment_type: "Refund",
      product_service_name: "Refund",
      staff_id: staff.id
      # notes: "Refund: #{reason}. Reference: #{id}"
    )
  end

  def extract_phone_number_from_appointment
    appointment.questions.find { |q| q.question == 'Phone number' }&.answer
  end
end
