# app/policies/coupon_policy.rb
class CouponPolicy < ApplicationPolicy
    def index?
      user.admin? || user.manager?
    end
  
    def show?
      user.admin? || user.manager?
    end
  
    def create?
      user.admin? || user.manager?
    end
  
    def new?
      create?
    end
  
    def update?
      user.admin? || user.manager?
    end
  
    def edit?
      update?
    end
  
    def destroy?
      user.admin?
    end
  
    def toggle_status?
      user.admin? || user.manager?
    end
  
    class Scope < Scope
      def resolve
        if user.admin? || user.manager?
          scope.all
        else
          scope.none
        end
      end
    end
end