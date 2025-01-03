class ReminderEmailJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    AppointmentMailer.reminder_email(appointment).deliver_now
  end
end
