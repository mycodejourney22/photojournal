class Studio < ApplicationRecord
    validates :name, :location, :address, :phone, :email, presence: true
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :active, inclusion: { in: [true, false] }
    
    has_many :appointments
    has_many :staff_assignments
    has_many :staff, through: :staff_assignments
    
    scope :active, -> { where(active: true) }
    
    def self.find_by_location_name(name)
      where("location ILIKE ?", "%#{name}%").first
    end
    
    def manager
      staff_assignments.find_by(role: 'manager')&.staff
    end
  end