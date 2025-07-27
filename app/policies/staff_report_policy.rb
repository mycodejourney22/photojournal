# app/policies/staff_report_policy.rb
class StaffReportPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        scope.all
      end
    end
  
    def index?
      # Allow managers, admins, or staff with reporting permissions
      user.present? && (user.admin? || user.manager? || has_reporting_access?)
    end
  
    def show?
      index?
    end
  
    def photographer_detail?
      index?
    end
  
    def editor_detail?
      index?
    end
  
    private
  
    def has_reporting_access?
      # Add custom logic based on your user model
      # For example, check if user has a specific role or permission
      user.role.in?(['Admin', 'Manager', 'Supervisor'])
    end
  end