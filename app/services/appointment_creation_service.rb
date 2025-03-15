# app/services/appointment_creation_service.rb
class AppointmentCreationService
  def initialize(params, current_user = nil)
    @params = params
    @current_user = current_user
  end

  def call
    appointment = Appointment.new(@params)
    appointment.set_defaults(@current_user)
    appointment.uuid = SecureRandom.uuid

    if appointment.save
      schedule_notifications(appointment)
      return { success: true, appointment: appointment }
    else
      return { success: false, appointment: appointment }
    end
  end

  private

  def schedule_notifications(appointment)
    appointment.schedule_policy_email
    appointment.schedule_reminder_email
    AppointmentNotificationJob.perform_later(appointment, 'created')
  end
end
