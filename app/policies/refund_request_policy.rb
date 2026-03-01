# app/policies/refund_request_policy.rb
class RefundRequestPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.manager? || user.super_admin?
        scope.all
      else
        case user.role
        when 'ikeja'
          scope.joins(:appointment).where("appointments.location ILIKE ?", "%ikeja%")
        when 'surulere'
          scope.joins(:appointment).where("appointments.location ILIKE ?", "%surulere%")
        when 'lekki'
          scope.joins(:appointment).where("appointments.location ILIKE ?", "%lekki%")
        when 'ajah'
          scope.joins(:appointment).where("appointments.location ILIKE ? OR appointments.location ILIKE ?", '%Ajah%', '%Ilaje%')
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
    user.admin? || user.manager? || user.super_admin? ||
      (user.ikeja? && record.appointment.location.downcase.include?('ikeja')) ||
      (user.lekki && record.appointment.location.downcase.include?('lekki')) ||
      (user.surulere? && record.appointment.location.downcase.include?('surulere')) ||
      (user.ajah? && (record.appointment.location.downcase.include?('ajah') || record.appointment.location.downcase.include?('ilaje')))
  end

  def approve?
    user.admin? || user.manager? || user.super_admin?
  end

  def decline?
    user.admin? || user.manager? || user.super_admin?
  end

  def process_refund?
    user.admin? || user.manager? || user.super_admin?
  end
end
