class Customer < ApplicationRecord
  has_many :sales, dependent: :nullify
  validates :phone_number, presence: true

  include PgSearch::Model
  pg_search_scope :global_search,
                  against: [ :name, :email, :phone_number],
                  using: {
                    tsearch: { prefix: true }
                  }

  def new_customer?
    visits_count <= 1
  end

  def increment_visits
    self.visits_count += 1
    save
  end
end
