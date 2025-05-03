class ReferralMailer < ApplicationMailer
  default from: '363 Photography'

  def invitation_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referral_url = referral_url(@referral.code, host: default_url_options[:host])

    mail_from_studio(
      {
        to: @referrer.email,
        subject: 'Refer friends to 363 Photography and earn ₦5,000 credit!'
      },
      @referral.location
    )
  end

  def referral_success_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referred = @referral.referred

    mail_from_studio(
      {
        to: @referrer.email,
        subject: 'You earned ₦5,000 credit for your referral!'
      },
      @referral.location
    )
  end

  def welcome_referred_customer_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referred = @referral.referred
    @discount_amount = @referral.referred_discount || 5000

    mail_from_studio(
      {
        to: @referred.email,
        subject: "Welcome to 363 Photography! You've received a ₦#{@discount_amount} discount!"
      },
      @referral.location
    )
  end
end
