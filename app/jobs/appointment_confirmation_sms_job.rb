# app/jobs/appointment_confirmation_sms_job.rb
class AppointmentConfirmationSmsJob < ApplicationJob
    queue_as :default
  
    def perform(appointment_id)
      appointment = Appointment.find_by(id: appointment_id)
      return unless appointment
  
      SmsService.new.send_appointment_confirmation_sms(appointment)
    end
  end