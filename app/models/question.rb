class Question < ApplicationRecord
  belongs_to :appointment

  QUESTIONS = [
    'Phone number',
    'Type of shoots'
  ].freeze
end
