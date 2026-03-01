# app/policies/appointment_report_policy.rb
class AppointmentReportPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah lekki].include?(user.role)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
