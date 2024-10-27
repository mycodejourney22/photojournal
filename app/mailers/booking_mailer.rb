class BookingMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.booking_mailer.reminder_email.subject
  #
  def reminder_email
    @booking = booking
    mail(to: @booking.email, subject: 'Your Upcoming Appointment Reminder')
  end

end
