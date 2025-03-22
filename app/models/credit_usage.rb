class CreditUsage < ApplicationRecord
  belongs_to :customer
  belongs_to :appointment

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :used_at, presence: true

  # Ensure we never use more credits than the appointment price
  validate :credits_do_not_exceed_price, if: -> { appointment.present? && amount.present? }

  private

  def credits_do_not_exceed_price
    if appointment.price && amount > appointment.price.amount
      errors.add(:amount, "cannot exceed the appointment price")
    end
  end
end
