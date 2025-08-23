# app/models/appointment_note.rb
class AppointmentNote < ApplicationRecord
    belongs_to :appointment
    belongs_to :created_by, class_name: 'User', optional: true
    belongs_to :actioned_by, class_name: 'User', optional: true
    
    validates :content, presence: true
    validates :note_type, presence: true, inclusion: { 
      in: %w[pre_shoot post_shoot editing general] 
    }
    validates :priority, inclusion: { in: 1..3 }
    
    # Scopes for different note types
    scope :pre_shoot, -> { where(note_type: 'pre_shoot') }
    scope :post_shoot, -> { where(note_type: 'post_shoot') }
    scope :editing, -> { where(note_type: 'editing') }
    scope :general, -> { where(note_type: 'general') }
    scope :high_priority, -> { where(priority: 3) }
    scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
    scope :actioned, -> { where(actioned: true) }
    scope :pending, -> { where(actioned: false) }
    
    # Human readable note types for internal use
    NOTE_TYPES = {
      'pre_shoot' => 'Pre-Shoot Instructions',
      'post_shoot' => 'Post-Shoot Notes', 
      'editing' => 'Editing Instructions',
      'general' => 'General Internal Notes'
    }.freeze
    
    PRIORITY_LABELS = {
      1 => 'Low',
      2 => 'Medium', 
      3 => 'High'
    }.freeze
    
    def note_type_label
      NOTE_TYPES[note_type] || note_type.humanize
    end
    
    def priority_label
      PRIORITY_LABELS[priority] || priority.to_s
    end
    
    def priority_class
      case priority
      when 3 then 'priority-high'
      when 2 then 'priority-medium'
      else 'priority-low'
      end
    end
    
    def mark_as_actioned!(user)
      update!(
        actioned: true,
        actioned_at: Time.current,
        actioned_by: user
      )
    end
    
    def mark_as_pending!
      update!(
        actioned: false,
        actioned_at: nil,
        actioned_by: nil
      )
    end
    
    def actioned_status
      if actioned?
        "Actioned #{actioned_at&.strftime('%b %d at %I:%M %p')} by #{actioned_by&.email}"
      else
        "Pending"
      end
    end
end