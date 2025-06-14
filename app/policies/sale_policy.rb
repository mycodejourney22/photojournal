class SalePolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   if user.admin? || user.manager? || user.super_admin?
    #     scope.all
    #   else
    #     case user.role
    #     when 'ikeja'
    #       scope.where("location ILIKE ?", '%ikeja%')
    #       .or(Sale.where(id: Sale.joins(:appointment).select(:id).where("appointments.location ILIKE ?", "%ikeja%")))
    #     when 'surulere'
    #       scope.where("location ILIKE ?", '%surulere%')
    #       .or(Sale.where(id: Sale.joins(:appointment).select(:id).where("appointments.location ILIKE ?", "%surulere%")))
    #     when 'ajah'
    #       scope.where("location ILIKE ? OR location ILIKE ?", '%Ajah%', '%Ilaje%')
    #            .or(Sale.where(id: Sale.joins(:appointment).select(:id).where("appointments.location ILIKE ?", "%Ajah%")))
    #     else
    #       scope.none
    #     end
    #   end
    # end
    def resolve
      if user.admin? || user.manager? || user.super_admin?
        scope.all
      else
        case user.role
        when 'ikeja'
          scope.joins(:studio).where(studios: { location: 'Ikeja' })
        when 'surulere'
          scope.joins(:studio).where(studios: { location: 'Surulere' })
        when 'ajah'
          scope.joins(:studio).where(studios: { location: 'Ajah' })
        else
          scope.none
        end
      end
    end
  end

  def index?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah].include?(user.role)
  end

  def new?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah].include?(user.role)
  end

  def create?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah].include?(user.role)
  end

  def edit?
    new?
  end

  def update?
    new?
  end
  def upfront?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah].include?(user.role)
  end
end
