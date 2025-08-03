class Price < ApplicationRecord
  has_many :appointments
  has_one_attached :photo

  scope :active, -> { where(active: true) } if column_names.include?('active')
  scope :inactive, -> { where(active: false) } if column_names.include?('active')

  include PgSearch::Model
  pg_search_scope :global_search,
  against: [ :name, :email],
    using: {
      tsearch: { prefix: true }
    }


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
end
