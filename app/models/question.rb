class Question < ApplicationRecord
  belongs_to :appointment

  QUESTIONS = [
    'Phone number',
    'Type of shoot'
  ].freeze
end
