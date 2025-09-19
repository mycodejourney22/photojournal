class PhotoShoot < ApplicationRecord
  include PgSearch::Model

  has_many :editor_assignments, dependent: :destroy
  has_one :current_editor_assignment, -> { where(status: 'active') }, class_name: 'EditorAssignment', foreign_key: 'photo_shoot_id'

  pg_search_scope :global_search,
    associated_against: {
      appointment:[ :name, :email]
    },
    using: {
      tsearch: { prefix: true }
    }
  belongs_to :appointment
  belongs_to :photographer, class_name: 'Staff', foreign_key: 'photographer_id', optional: true
  belongs_to :editor, class_name: 'Staff', foreign_key: 'editor_id', optional: true
  belongs_to :customer_service, class_name: 'Staff', foreign_key: 'customer_service_id', optional: true
  has_one :sale, dependent: :destroy
  accepts_nested_attributes_for :sale
  validates :date, presence: true

  def assign_editor!(editor, assigned_by: nil, notes: nil)
    transaction do
      # Mark any existing active assignment as reassigned
      current_editor_assignment&.update!(status: 'reassigned')
      
      # Update the PhotoShoot editor (maintains existing functionality)
      update!(editor: editor)
      
      # Create new assignment record
      editor_assignments.create!(
        # photo_shoot: self,
        editor: editor,
        assigned_by: assigned_by,
        assigned_at: Time.current,
        status: 'active',
        notes: notes
      )
    end
  end
  
  # Method to get assignment date for the current editor
  def editor_assigned_at
    current_editor_assignment&.assigned_at || updated_at
  end
end
