# app/models/editor_assignment.rb
class EditorAssignment < ApplicationRecord
    belongs_to :photo_shoot, class_name: 'PhotoShoot'
    belongs_to :editor, class_name: 'Staff'
    belongs_to :assigned_by, class_name: 'Staff', optional: true
    
    validates :assigned_at, presence: true
    validates :status, presence: true, inclusion: { in: %w[active reassigned cancelled] }
    
    # Ensure only one active assignment per photoshoot
    validates :photo_shoot_id, uniqueness: { scope: :status }, if: :active?
    
    scope :active, -> { where(status: 'active') }
    scope :by_date_range, ->(start_date, end_date) { where(assigned_at: start_date.beginning_of_day..end_date.end_of_day) }
    scope :assigned_on, ->(date) { where(assigned_at: date.beginning_of_day..date.end_of_day) }
    
    before_validation :set_assigned_at, on: :create
    
    private
    
    def active?
      status == 'active'
    end
    
    def set_assigned_at
      self.assigned_at ||= Time.current
    end
  end