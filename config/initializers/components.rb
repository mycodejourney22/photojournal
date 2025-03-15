Rails.application.config.after_initialize do
  require_dependency Rails.root.join('app/components/appointment_card_component')
end
