class AppointmentNotificationJob < ApplicationJob
  queue_as :default

  def perform(appointment, action)
    case action
    when 'created'
      AppointmentMailer.appointment_created(appointment).deliver_later
    when 'edited'
      AppointmentMailer.appointment_edited(appointment).deliver_later
    when 'canceled'
      AppointmentMailer.appointment_canceled(appointment).deliver_later
    end
  end
end
