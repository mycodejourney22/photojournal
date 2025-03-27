class Referral < ApplicationRecord
  belongs_to :referrer, class_name: 'Customer'
  belongs_to :referred, class_name: 'Customer', optional: true

  validates :code, presence: true
  validates :status, presence: true, inclusion: { in: %w[active converted rewarded expired] }

  # Ex: R-JOHN-1A2B3C
  before_validation :generate_code, on: :create
  before_validation :set_default_amounts, on: :create

  # Status constants for better code readability
  ACTIVE = 'active'
  CONVERTED = 'converted'
  REWARDED = 'rewarded'
  EXPIRED = 'expired'

  # Scopes for easy querying
  scope :active, -> { where(status: ACTIVE) }
  scope :converted, -> { where(status: CONVERTED) }
  scope :rewarded, -> { where(status: REWARDED) }
  scope :not_rewarded, -> { where.not(status: REWARDED) }
  scope :by_code, ->(code) { where(code: code) }

  def converted?
    status == CONVERTED || status == REWARDED
  end

  def rewarded?
    status == REWARDED
  end

  def active?
    status == ACTIVE
  end

  # Find or create a customer's active referral code
  def self.active_code_for_customer(customer)
    active_referral = customer.referrals_made.active.first

    # If no active referral exists, create one
    if active_referral.nil?
      active_referral = customer.referrals_made.create!(status: ACTIVE)
    end

    active_referral.code
  end

  # Check if a customer is eligible to use a referral code
  # Only new customers with no sales history can use referral codes
  def self.customer_eligible_for_referral?(customer)
    return false unless customer

    # A customer is eligible if they:
    # 1. Have never made a purchase
    # 2. Have no previous photoshoots
    # 3. Have never used a referral code before

    # Check if they have any sales
    return false if customer.sales.exists?

    # Check if they have any photoshoots via appointments
    # has_photoshoots = Appointment.joins(:photo_shoot)
    #                              .where(email: customer.email)
    #                              .or(Appointment.joins(:questions)
    #                                         .where(questions: { question: 'Phone number', answer: customer.phone_number }))
    #                              .exists?
    # return false if has_photoshoots

    # Check if they've used a referral code before
    used_referral_before = customer.referrals_received.where.not(parent_code: nil).count > 1
    return false if used_referral_before

    # If all checks pass, customer is eligible
    true
  end

  # Create a new converted referral instance for a specific referred customer
  # Returns nil if the referred customer is not eligible for a referral
# Modify the create_conversion method
  def self.create_conversion(code, referred_customer)
    # Find the original referral with this code
    original_referral = where(code: code, status: ACTIVE).first
    return nil unless original_referral

    # Don't allow self-referrals
    return nil if original_referral.referrer_id == referred_customer.id

    # Check if the customer is eligible (new customer)
    return nil unless customer_eligible_for_referral?(referred_customer)

    # Check if conversion already exists for this referral code and customer
    existing_conversion = where(
      code: code,
      referred_id: referred_customer.id,
      status: [CONVERTED, REWARDED]
    ).first

    # Return existing conversion if it exists
    return existing_conversion if existing_conversion

    # Create a new referral record to track this specific conversion
    new_conversion = Referral.new(
      code: "#{code}-#{SecureRandom.hex(4)}", # Make code unique by adding suffix
      referrer: original_referral.referrer,
      referred: referred_customer,
      status: CONVERTED,
      converted_at: Time.current,
      reward_amount: original_referral.reward_amount,
      referred_discount: original_referral.referred_discount,
      parent_code: code
    )

    new_conversion.save

    # Send welcome email to the referred customer
    ReferralMailer.welcome_referred_customer_email(new_conversion).deliver_later

    new_conversion
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

  # Process reward and credit the referrer
  def process_reward
    return false unless converted? && referred_has_purchase? && !rewarded?

    # Add the reward amount to the referrer's credits
    amount = reward_amount || 5000
    referrer.credits += amount
    referrer.save

    # Mark this referral as rewarded
    mark_as_rewarded

    # Send success email
    ReferralMailer.referral_success_email(self).deliver_later

    true
  end

  private

  def generate_code
    return if code.present?

    # Create a code based on the referrer's name and a random string
    name_part = referrer.name.split(' ').first.upcase[0..3] rescue 'CUST'
    random_part = SecureRandom.alphanumeric(6).upcase

    self.code = "R-#{name_part}-#{random_part}"
  end

  def set_default_amounts
    self.reward_amount = 5000  # ₦5,000 reward for referrer
    self.referred_discount ||= 5000  # ₦5,000 discount for referred customer
  end
end
