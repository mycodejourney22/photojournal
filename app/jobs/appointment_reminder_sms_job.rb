# app/jobs/appointment_reminder_sms_job.rb
class AppointmentReminderSmsJob < ApplicationJob
    queue_as :default
  
    def perform(appointment_id, reminder_type = '24_hours')
      appointment = Appointment.find_by(id: appointment_id)
      return unless appointment
  
      # Don't send reminders for cancelled appointments
      return unless appointment.status
  
      SmsService.new.send_appointment_reminder_sms(appointment, reminder_type)
    end
  end