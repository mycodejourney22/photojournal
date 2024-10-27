class ThankYouEmailJob < ApplicationJob
  queue_as :default

  def perform(photoshoot)
    PhotoMailer.thank_you_email(photoshoot).deliver_now
  end
end
