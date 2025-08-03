class Staff < ApplicationRecord
  has_many :photo_shoots_as_photographer, class_name: 'PhotoShoot', foreign_key: 'photographer_id'
  has_many :photo_shoots_as_editor, class_name: 'PhotoShoot', foreign_key: 'editor_id'
  has_many :photo_shoots_as_customer_service, class_name: 'PhotoShoot', foreign_key: 'customer_service_id'
  has_many :sales

  scope :active, -> { where(active: true) } if column_names.include?('active')
  scope :photographers, -> { where(role: 'Photographer') } if column_names.include?('role')
  scope :editors, -> { where(role: 'Editor') } if column_names.include?('role')
  scope :customer_service, -> { where(role: 'Customer Service') } if column_names.include?('role')
  scope :by_location, ->(location) { where(location: location) } if column_names.include?('location')
  
  def display_name
    if respond_to?(:role) && role.present?
      "#{name} (#{role})"
    else
      name
    end
  end

  def active?
    return true unless respond_to?(:active)
    active
  end
end
