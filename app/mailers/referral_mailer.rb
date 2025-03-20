class ReferralMailer < ApplicationMailer
  default from: '363 Photography'

  def invitation_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referral_url = referral_url(@referral.code, host: default_url_options[:host])

    mail(
      to: @referrer.email,
      subject: 'Refer friends to 363 Photography and earn ₦10,000 credit!'
    )
  end

  def referral_success_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referred = @referral.referred

    mail(
      to: @referrer.email,
      subject: 'You earned ₦10,000 credit for your referral!'
    )
  end

  def welcome_referred_customer_email(referral)
    @referral = referral
    @referrer = @referral.referrer
    @referred = @referral.referred
    @discount_amount = @referral.referred_discount || 5000

    mail(
      to: @referred.email,
      subject: "Welcome to 363 Photography! You've received a ₦#{@discount_amount/100} discount!"
    )
  end
end
