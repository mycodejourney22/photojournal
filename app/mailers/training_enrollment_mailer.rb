# app/mailers/training_enrollment_mailer.rb
class TrainingEnrollmentMailer < ApplicationMailer
  default from: '363 Photography <info@363photography.org>'

  # Email sent to admin when someone enrolls
  def admin_notification(enrollment)
    @enrollment = enrollment

    mail(
      to: 'info@363photography.org', # Change to your admin email
      subject: "🎓 New Training Enrollment: #{@enrollment.full_name}"
    )
  end

  # Confirmation email sent to the applicant
  def applicant_confirmation(enrollment)
    @enrollment = enrollment

    mail(
      to: @enrollment.email,
      subject: "Thank you for applying to 363 Photography Training!"
    )
  end
end
