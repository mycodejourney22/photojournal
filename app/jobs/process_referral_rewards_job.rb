class ProcessReferralRewardsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all converted referrals where the referred customer has a sale, but referrer hasn't been rewarded
    pending_referrals = Referral.where(status: Referral::CONVERTED)

    pending_referrals.each do |referral|
      # Skip if no referred customer or they don't have a sale yet
      next unless referral.referred_has_purchase?

      # Apply the reward to the referrer
      referrer = referral.referrer

      # Add the reward amount to the referrer's credits
      reward_amount = referral.reward_amount || 10000
      referrer.credits += reward_amount
      referrer.save

      # Mark the referral as rewarded
      referral.mark_as_rewarded

      # Send success email to referrer
      ReferralMailer.referral_success_email(referral).deliver_later
    end
  end
end
