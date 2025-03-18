class ThankYouSmsJob < ApplicationJob
  queue_as :default

  def perform(photoshoot_id)
    photoshoot = PhotoShoot.find_by(id: photoshoot_id)
    return unless photoshoot

    SmsService.new.send_thank_you_sms(photoshoot)
  end
end
