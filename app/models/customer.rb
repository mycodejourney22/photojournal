class Customer < ApplicationRecord
  has_many :sales, dependent: :nullify
  validates :phone_number, presence: true

  def new_customer?
    visits_count <= 1
  end

  def increment_visits
    self.visits_count += 1
    save
  end
end
