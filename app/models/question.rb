class Question < ApplicationRecord
  belongs_to :appointment

  QUESTIONS = [
    'Phone number',
    'Type of shoots',
    'Do you give us consent to share your pictures on our social media platform (Instagram, Threads, TikTok e.t.c) ?'
  ].freeze
end
