# app/models/coupon.rb
class Coupon < ApplicationRecord
    TYPES = %w[fixed_amount percentage referral seasonal adhoc].freeze
    STATUSES = %w[active inactive expired].freeze
    
    validates :code, presence: true, uniqueness: { case_sensitive: false }
    validates :coupon_type, inclusion: { in: TYPES }
    validates :status, inclusion: { in: STATUSES }
    validates :discount_amount, presence: true, numericality: { greater_than: 0 }, if: -> { fixed_amount_type? }
    validates :discount_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, if: -> { percentage_type? }
    validates :max_uses, presence: true, numericality: { greater_than: 0 }
    
    # Scopes
    scope :active, -> { where(status: 'active') }
    scope :valid_for_use, -> { active.where('expires_at IS NULL OR expires_at > ?', Time.current) }
    scope :by_code, ->(code) { where('UPPER(code) = ?', code.upcase.strip) }
    
    # Before save callbacks
    before_validation :normalize_code
    before_validation :set_default_values
    
    def valid_for_use?
      return false unless active?
      return false if expired?
      return false if usage_limit_reached?
      true
    end
    
    def calculate_discount(amount)
      return 0 unless valid_for_use?
      return 0 if minimum_amount.present? && amount < minimum_amount.to_i
      
      discount = case coupon_type
      when 'fixed_amount'
        discount_amount
      when 'percentage'
        (amount * discount_percentage / 100.0).round
      when 'referral', 'seasonal', 'adhoc'
        discount_amount
      else
        0
      end
      
      # Don't let discount exceed the total amount
      [discount, amount].min
    end
    
    def increment_usage!
      increment!(:usage_count)
      update!(status: 'expired') if usage_count >= max_uses
    end
    
    def expired?
      expires_at.present? && expires_at < Time.current
    end
    
    def usage_limit_reached?
      usage_count >= max_uses
    end
    
    def active?
      status == 'active'
    end
    
    def self.find_valid_coupon(code)
      return nil if code.blank?
      
      coupon = by_code(code).first
      return nil unless coupon&.valid_for_use?
      
      coupon
    end
    
    private
    
    def normalize_code
      self.code = code.upcase.strip if code.present?
    end
    
    def set_default_values
      self.discount_amount ||= 0 if fixed_amount_type?
      self.discount_percentage ||= 0 if percentage_type?
    end
    
    def fixed_amount_type?
      %w[fixed_amount referral seasonal adhoc].include?(coupon_type)
    end
    
    def percentage_type?
      coupon_type == 'percentage'
    end
end