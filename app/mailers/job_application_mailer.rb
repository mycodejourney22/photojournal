# # app/mailers/job_application_mailer.rb
# class JobApplicationMailer < ApplicationMailer
#   default from: '363 Photography <noreply@363photography.org>'

#   # Email sent to HR when a new application is submitted
#   def hr_notification(job_application)
#     @job_application = job_application
#     @cv_url = rails_blob_url(@job_application.cv) if @job_application.cv.attached?

#     # Prepare portfolio URLs
#     @portfolio_urls = []
#     if @job_application.portfolio_files.attached?
#       @job_application.portfolio_files.each do |file|
#         @portfolio_urls << { name: file.filename.to_s, url: rails_blob_url(file) }
#       end
#     end

#     mail(
#       to: 'hr@363photography.org',
#       subject: "New Job Application: #{@job_application.position} - #{@job_application.name}"
#     )
#   end

#   # Confirmation email sent to the applicant
#   def applicant_confirmation(job_application)
#     @job_application = job_application

#     mail(
#       to: @job_application.email,
#       subject: "Application Received - #{@job_application.position} at 363 Photography"
#     )
#   end
# end
# app/mailers/job_application_mailer.rb
# app/mailers/job_application_mailer.rb
class JobApplicationMailer < ApplicationMailer
  default from: '363 Photography <noreply@363photography.org>'

  # Email sent to HR when a new application is submitted
  # Files are attached directly to the email for easy access
  # Wasabi storage serves as backup
  def hr_notification(job_application)
    @job_application = job_application
    @large_files = []
    @attachment_errors = []

    # Attach CV directly to email
    if @job_application.cv.attached?
      begin
        attachments[@job_application.cv.filename.to_s] = {
          mime_type: @job_application.cv.content_type,
          content: @job_application.cv.download
        }
      rescue => e
        Rails.logger.error "Failed to attach CV: #{e.message}"
        @attachment_errors << @job_application.cv.filename.to_s
      end
    end

    # Attach portfolio files directly to email
    # Only attach files under 5MB each to avoid email size issues
    if @job_application.portfolio_files.attached?
      @job_application.portfolio_files.each do |file|
        begin
          if file.byte_size <= 5.megabytes
            attachments[file.filename.to_s] = {
              mime_type: file.content_type,
              content: file.download
            }
          else
            @large_files << { name: file.filename.to_s, size: file.byte_size }
          end
        rescue => e
          Rails.logger.error "Failed to attach portfolio file #{file.filename}: #{e.message}"
          @attachment_errors << file.filename.to_s
        end
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
