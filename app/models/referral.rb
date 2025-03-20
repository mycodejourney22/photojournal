class Referral < ApplicationRecord
  belongs_to :referrer, class_name: 'Customer'
  belongs_to :referred, class_name: 'Customer', optional: true

  validates :code, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending converted rewarded expired] }

  # Ex: R-JOHN-1A2B3C
  before_validation :generate_code, on: :create

  # Status constants for better code readability
  PENDING = 'pending'
  CONVERTED = 'converted'
  REWARDED = 'rewarded'
  EXPIRED = 'expired'

  # Scopes for easy querying
  scope :pending, -> { where(status: PENDING) }
  scope :converted, -> { where(status: CONVERTED) }
  scope :rewarded, -> { where(status: REWARDED) }
  scope :not_rewarded, -> { where.not(status: REWARDED) }
  scope :active, -> { where.not(status: EXPIRED) }

  def converted?
    status == CONVERTED || status == REWARDED
  end

  def rewarded?
    status == REWARDED
  end

  def pending?
    status == PENDING
  end

  # Method to record when someone signs up using this referral
  def mark_as_used(customer)
    update(
      referred: customer,
      status: CONVERTED,
      converted_at: Time.current
    )
  end

  # Mark as rewarded when the referred customer completes their first purchase
  def mark_as_rewarded
    update(
      status: REWARDED,
      rewarded_at: Time.current
    )
  end

  # Check if the referred customer has a sale
  def referred_has_purchase?
    return false unless referred.present?
    referred.sales.where(void: false).exists?
  end

  private

  def generate_code
    return if code.present?

    # Create a code based on the referrer's name and a random string
    name_part = referrer.name.split(' ').first.upcase[0..3] rescue 'CUST'
    random_part = SecureRandom.alphanumeric(6).upcase

    self.code = "R-#{name_part}-#{random_part}"
  end
end
