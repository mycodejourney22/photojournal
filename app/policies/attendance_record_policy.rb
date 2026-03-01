# app/policies/attendance_record_policy.rb
class AttendanceRecordPolicy < ApplicationPolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.super_admin?
          # Admins see everything
          scope.all
        elsif user.manager? && user.studio_id.present?
          # Managers see only their studio's data
          scope.by_studio_id(user.studio_id)
        elsif %w[ikeja surulere ajah lekki].include?(user.role)
          # Generic studio accounts cannot access attendance
          scope.none
        else
          scope.none
        end
      end
    end

    def index?
      # Only managers (with studio) and admins can view
      (user.manager? && user.studio_id.present?) || user.admin? || user.super_admin?
    end

    def upload?
      # Only managers (with studio) and admins can upload
      (user.manager? && user.studio_id.present?) || user.admin? || user.super_admin?
    end

    def import?
      upload?
    end

    def report?
      index?
    end
end
