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

    def self.find_by_location_from_text(text)
        return nil unless text.present?
        
        text = text.downcase.strip
        
        # Try direct match first
        studio = find_by("LOWER(location) = ?", text)
        return studio if studio
        
        # Try pattern matching
        if text =~ /surulere|bode thomas/i
            return find_by("LOWER(location) LIKE ?", "%surulere%")
        elsif text =~ /ikeja|adeniyi jones/i
            return find_by("LOWER(location) LIKE ?", "%ikeja%")
        elsif text =~ /ajah|ilaje|lekki epe/i
            return find_by("LOWER(location) LIKE ?", "%ajah%")
        end
        
        nil
    end
  end