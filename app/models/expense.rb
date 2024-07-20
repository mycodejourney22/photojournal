class Expense < ApplicationRecord
  validates :date, :description, :category, :staff, :amount, :location, presence: true
end
