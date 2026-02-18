class Price < ApplicationRecord
  has_many :appointments
  has_one_attached :photo
  belongs_to :studio, optional: true

  scope :active, -> { where(active: true) } if column_names.include?('active')
  scope :inactive, -> { where(active: false) } if column_names.include?('active')

  include PgSearch::Model
  pg_search_scope :global_search,
  against: [ :name, :email],
    using: {
      tsearch: { prefix: true }
    }

   # Returns prices available for a specific location
  # - Prices with no studio_id (global prices) are available everywhere
  # - Prices with a studio_id are only available at that studio

scope :for_location, ->(location) {
  return where(studio_id: nil) if location.blank?

  studio = location.is_a?(Studio) ? location : Studio.find_by_location_name(location)

  if studio
    # Check if this studio has its own specific prices
    studio_specific_exists = where(studio_id: studio.id).exists?

    if studio_specific_exists
      # If studio has specific prices, show ONLY those (not global)
      where(studio_id: studio.id)
    else
      # If no studio-specific prices, show global prices
      where(studio_id: nil)
    end
  else
    where(studio_id: nil)
  end
}

  # Returns only studio-specific prices (excludes global prices)
  scope :exclusive_to_studio, ->(studio_or_location) {
    studio = studio_or_location.is_a?(Studio) ? studio_or_location : Studio.find_by_location_name(studio_or_location)
    where(studio_id: studio&.id)
  }

  # Returns only global prices (available at all studios)
  scope :global, -> { where(studio_id: nil) }

  def formatted_start_time
    created_at.strftime("%A, %d %B %Y")
  end

  def formatted_time
    created_at.in_time_zone('West Central Africa').strftime("%I:%M %p")
  end


  def display_name
    if respond_to?(:name) && name.present?
      "#{name} - #{shoot_type}"
    else
      shoot_type
    end
  end

  def formatted_amount
    "₦#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def active?
    return true unless respond_to?(:active)
    active
  end

    # Check if this price is studio-specific
  def studio_specific?
    studio_id.present?
  end

  # Check if this price is global (available at all studios)
  def global?
    studio_id.nil?
  end

  # Get the studio name or "All Studios" for global prices
  def studio_name
    studio&.location || "All Studios"
  end
end
