class PhotoShoot < ApplicationRecord
  include PgSearch::Model
  pg_search_scope :global_search,
    associated_against: {
      appointment:[ :name, :email]
    },
    using: {
      tsearch: { prefix: true }
    }
  belongs_to :appointment
  belongs_to :photographer, class_name: 'Staff', foreign_key: 'photographer_id', optional: true
  belongs_to :editor, class_name: 'Staff', foreign_key: 'editor_id', optional: true
  belongs_to :customer_service, class_name: 'Staff', foreign_key: 'customer_service_id', optional: true
  has_one :sale, dependent: :destroy
  accepts_nested_attributes_for :sale
end
