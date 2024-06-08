class PhotoShoot < ApplicationRecord
  belongs_to :appointment
  belongs_to :photographer, class_name: 'Staff', foreign_key: 'photographer_id', optional: true
  belongs_to :editor, class_name: 'Staff', foreign_key: 'editor_id', optional: true
  belongs_to :customer_service, class_name: 'Staff', foreign_key: 'customer_service_id', optional: true
end
