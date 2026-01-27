# app/mailers/job_application_mailer.rb
class JobApplicationMailer < ApplicationMailer
  default from: '363 Photography <noreply@363photography.org>'

  # Email sent to HR when a new application is submitted
  def hr_notification(job_application)
    @job_application = job_application
    @cv_url = rails_blob_url(@job_application.cv) if @job_application.cv.attached?

    # Prepare portfolio URLs
    @portfolio_urls = []
    if @job_application.portfolio_files.attached?
      @job_application.portfolio_files.each do |file|
        @portfolio_urls << { name: file.filename.to_s, url: rails_blob_url(file) }
      end
    end

    mail(
      to: 'hr@363photography.org',
      subject: "New Job Application: #{@job_application.position} - #{@job_application.name}"
    )
  end

  # Confirmation email sent to the applicant
  def applicant_confirmation(job_application)
    @job_application = job_application

    mail(
      to: @job_application.email,
      subject: "Application Received - #{@job_application.position} at 363 Photography"
    )
  end
end
