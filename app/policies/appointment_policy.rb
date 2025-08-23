class AppointmentPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      if user.admin? || user.manager? || user.super_admin?
        scope.all
      else
        case user.role
        when 'ikeja'
          scope.where('location iLIKE ?', '%Ikeja%')
        when 'surulere'
          scope.where('location iLIKE ?', '%Surulere%')
        when 'ajah'
          scope.where('location ILIKE ? OR location ILIKE ?', '%Ajah%', '%Ilaje%')
        else
          scope.none
        end
      end
    end
  end

  def index?
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah social].include?(user.role)
  end

  def past?
    index?
  end

  def in_progress?
    # Same access control as other appointment views
    user.admin? || user.manager? || user.super_admin? || %w[ikeja surulere ajah].include?(user.role)
  end
  
  def upcoming?
    index?
  end

  def mark_no_show?
    true
  end

  def add_note?
    true
  end

  def remove_note?
    true
  end

  def toggle_note_action?
    true
  end

  def new?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def new_customer?
    true
  end

  def booking?
    true
  end

  def available_hours?
    true
  end

  def type_of_shoots?
    true
  end

  def selected_date?
    true
  end

  def edit?
    true
  end

  def customer_pictures?
    show?
  end

  def select_price?
    true
  end

  def photo_inspirations?
    show?
  end

  def update?
    true
  end

  def cancel_booking?
    true
  end

  def cancel?
    true
  end

  def thank_you?
    true
  end
end
