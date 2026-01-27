# app/policies/job_application_policy.rb
class JobApplicationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.super_admin? || user.manager?
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    user.admin? || user.super_admin? || user.manager?
  end

  def show?
    user.admin? || user.super_admin? || user.manager?
  end

  def new?
    true # Public access
  end

  def create?
    true # Public access
  end

  def update?
    user.admin? || user.super_admin?
  end

  def download_cv?
    user.admin? || user.super_admin? || user.manager?
  end
end
