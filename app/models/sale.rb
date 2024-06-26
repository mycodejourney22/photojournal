class Sale < ApplicationRecord
  # validates :date, presence: true
  # validates :amount_paid, presence: true, numericality: { greater_than_or_equal_to: 0 }
  # validates :payment_method, presence: true
  # validates :payment_type, presence: true
  # validates :customer_name, presence: true
  # validates :customer_service_officer_name, presence: true
  # validates :product_service_name, presence: true
  # belongs_to :photo_shoot, optional: true
  include PgSearch::Model
  pg_search_scope :global_search,
  against: [ :customer_name, :customer_phone_number , :payment_type],
    using: {
      tsearch: { prefix: true }
    }

end
