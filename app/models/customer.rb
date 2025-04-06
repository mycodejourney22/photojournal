class Customer < ApplicationRecord
  include PhoneNumberNormalizer
  before_validation :normalize_phone_number_field
  has_many :sales, dependent: :nullify
  validates :phone_number, presence: true
  has_many :referrals_made, class_name: 'Referral', foreign_key: 'referrer_id', dependent: :nullify
  has_many :referrals_received, class_name: 'Referral', foreign_key: 'referred_id', dependent: :nullify
  after_commit :sync_with_brevo, on: [:create, :update]


  attribute :credits, :integer, default: 0

  include PgSearch::Model
  pg_search_scope :global_search,
                  against: [ :name, :email, :phone_number],
                  using: {
                    tsearch: { prefix: true }
                  }

  def new_customer?
    visits_count <= 1
  end

  def increment_visits
    self.visits_count += 1
    save
  end

  def generate_referral
    referrals_made.create!(status: Referral::ACTIVE)
  end

  def referral_code
    # Find an active referral or create one if none exists
    Referral.active_code_for_customer(self)
  end

  # Get the active referral code for this customer
  def active_referral
    referrals_made.active.order(created_at: :desc).first || generate_referral
  end

  def pending_rewards
    referrals_made.where(status: Referral::CONVERTED)
  end

  # Process all pending rewards for this customer
  def apply_referral_rewards
    # Find conversions that have referred customers with sales
    successful_referrals = pending_rewards.select(&:referred_has_purchase?)

    return 0 if successful_referrals.empty?

    total_reward = 0

    successful_referrals.each do |referral|
      # Add the reward amount to this customer's credits
      reward_amount = referral.reward_amount || 10000
      self.credits += reward_amount
      total_reward += reward_amount

      # Mark referral as rewarded
      referral.mark_as_rewarded

      # Send success email
      ReferralMailer.referral_success_email(referral).deliver_later
    end

    self.save
    total_reward
  end

  # Add a specific amount of referral credits
  def add_referral_credit(amount)
    self.credits += amount
    save
  end

  # Use credits for a purchase (optional, for future use)
  def use_credits(amount)
    return false if credits < amount

    self.credits -= amount
    save
  end

  private

  def normalize_phone_number_field
    self.phone_number = normalize_phone_number(phone_number) if phone_number.present?
  end
end
