# app/jobs/appointment_update_sms_job.rb
class AppointmentUpdateSmsJob < ApplicationJob
  queue_as :default

  def perform(appointment_id, action)
    appointment = Appointment.find_by(id: appointment_id)
    return unless appointment

    sms_service = SmsService.new

    case action
    when 'updated'
      sms_service.send_appointment_update_sms(appointment)
    when 'cancelled'
      sms_service.send_appointment_cancellation_sms(appointment)
    end
  end
end