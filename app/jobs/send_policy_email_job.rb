class SendPolicyEmailJob < ApplicationJob
  queue_as :default

  def perform(appointment_id)
    appointment = Appointment.find(appointment_id)
    AppointmentMailer.policy_email(appointment).deliver_now
  end
end
