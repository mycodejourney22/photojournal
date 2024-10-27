class ReminderEmailJob < ApplicationJob
  queue_as :default

  def perform(appointment)
    AppointmentMailer.reminder_email(appointment).deliver_now
  end
end
