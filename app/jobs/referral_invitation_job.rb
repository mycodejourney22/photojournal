class ReferralInvitationJob < ApplicationJob
  queue_as :default

  def perform(photoshoot_id)
    photoshoot = PhotoShoot.find_by(id: photoshoot_id)
    return unless photoshoot

    # Skip if no appointment or appointment has no customer
    appointment = photoshoot.appointment
    return unless appointment

    # Find or create the customer
    phone_number = appointment.questions.find { |q| q.question == 'Phone number' }&.answer
    return unless phone_number

    customer = Customer.find_by(phone_number: phone_number)
    return unless customer

    # Generate a referral code if one doesn't exist
    referral = customer.active_referral

    # Send the email
    ReferralMailer.invitation_email(referral).deliver_now
  end
end
