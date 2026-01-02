# app/policies/expense_report_policy.rb
class ExpenseReportPolicy < ApplicationPolicy
  def index?
    user.present? && (user.admin? || user.manager? || user.super_admin?)
  end
end
