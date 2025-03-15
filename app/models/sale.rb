class Sale < ApplicationRecord
  validates :date, presence: true
  belongs_to :customer, optional: true
  belongs_to :staff
  validates :amount_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  # validates :customer_phone_number, presence: true
  validates :payment_type, presence: true
  # validates :customer_name, presence: true
  # validates :customer_service_officer_name, presence: true
  validates :product_service_name, presence: true
  # belongs_to :photo_shoot, optional: true
  include PgSearch::Model
  belongs_to :appointment, optional: true
  pg_search_scope :global_search,
  against: [ :customer_name, :customer_phone_number , :payment_type],
    using: {
      tsearch: { prefix: true }
    }


    # Add more meaningful scopes to improve readability
  scope :by_product, ->(product) { where(product_service_name: product) }
  scope :by_payment_type, ->(type) { where(payment_type: type) }

  # Adding a custom validation
  validate :customer_name_or_appointment_required

  private

  def customer_name_or_appointment_required
    if customer_name.blank? && appointment_id.blank?
      errors.add(:base, "Either customer name or appointment must be provided")
    end
  end
end
