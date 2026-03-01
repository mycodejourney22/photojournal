class ReferralPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.manager? || user.super_admin?
        scope.all
      else
        case user.role
        when 'ikeja'
          scope.joins(referrer: :sales).where("sales.location ILIKE ?", "%ikeja%").distinct
        when 'surulere'
          scope.joins(referrer: :sales).where("sales.location ILIKE ?", "%surulere%").distinct
        when 'lekki'
          scope.joins(referrer: :sales).where("sales.location ILIKE ?", "%lekki%").distinct
        when 'ajah'
          scope.joins(referrer: :sales).where("sales.location ILIKE ? OR sales.location ILIKE ?", '%Ajah%', '%Ilaje%').distinct
        else
          scope.none
        end
      end
    end
  end

  def index?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah lekki].include?(user.role)
  end

  def show?
    true # Public access to referral landing pages
  end

  def apply?
    true # Public access to apply a referral
  end

  def create?
    user.admin? || user.manager? || user.super_admin?
  end

  def update?
    user.admin? || user.manager? || user.super_admin?
  end

  def process_pending_rewards?
    user.admin? || user.manager? || user.super_admin?
  end
end
