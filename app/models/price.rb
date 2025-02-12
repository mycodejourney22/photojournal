class Price < ApplicationRecord
  has_many :appointments
  has_one_attached :photo



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
end
