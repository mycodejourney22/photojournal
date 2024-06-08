class Staff < ApplicationRecord
  has_many :photo_shoots_as_photographer, class_name: 'PhotoShoot', foreign_key: 'photographer_id'
  has_many :photo_shoots_as_editor, class_name: 'PhotoShoot', foreign_key: 'editor_id'
  has_many :photo_shoots_as_customer_service, class_name: 'PhotoShoot', foreign_key: 'customer_service_id'
end
