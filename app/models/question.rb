class Question < ApplicationRecord
  belongs_to :appointment
  validates :answer, presence: true, if: :required_question?


  QUESTIONS = [
    'Phone number',
    'Type of shoots',
    'Do you give us consent to share your pictures on our social media platform (Instagram, Threads, TikTok e.t.c) ?'
  ].freeze

  def required_question?
    self.question == 'Do you give us consent to share your pictures on our social media platform (Instagram, Threads, TikTok e.t.c) ?' ||
    self.question == 'Type of shoots'
  end
end
