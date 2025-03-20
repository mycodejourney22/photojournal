class ReferralsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :apply]
  before_action :set_referral, only: [:show, :apply]
  layout 'public', only: [:show]

  def index
    authorize Referral
    @referrals = policy_scope(Referral).includes(:referrer, :referred).order(created_at: :desc)

    # Filter by status if requested
    if params[:status].present?
      @referrals = @referrals.where(status: params[:status])
    end

    @referrals = @referrals.page(params[:page])
  end

  def show
    # Public landing page for a referral
    if @referral.nil?
      redirect_to public_home_path, alert: "Invalid referral code."
      return
    end
  end

  def apply
    # Process and store the referral code in the session
    if @referral.nil?
      redirect_to public_home_path, alert: "Invalid referral code."
      return
    end

    if @referral.converted? || @referral.rewarded?
      redirect_to public_home_path, alert: "This referral code has already been used."
      return
    end

    # Store the referral code in session for later use during signup/booking
    session[:referral_code] = @referral.code

    # Redirect to booking page with the referral code applied
    redirect_to type_of_shoots_appointments_path, notice: "Referral discount will be applied to your booking!"
  end

  def process_rewards
    authorize Referral, :process_pending_rewards?
    ProcessReferralRewardsJob.perform_later
    redirect_to referrals_path, notice: "Processing referral rewards. This may take a few moments."
  end

  private

  def set_referral
    @referral = Referral.find_by(code: params[:code])
  end
end
