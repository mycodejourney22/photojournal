# app/controllers/training_controller.rb
class TrainingController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'training'

  def index
    # Public training landing page - no authentication required
  end

  def enroll
    @enrollment = TrainingEnrollment.new(enrollment_params)

    if @enrollment.save
      # Send notification email to admin
      TrainingEnrollmentMailer.admin_notification(@enrollment).deliver_later

      # Send confirmation email to applicant
      TrainingEnrollmentMailer.applicant_confirmation(@enrollment).deliver_later

      redirect_to training_path, notice: "Thank you for your application, #{@enrollment.first_name}! We'll contact you within 24 hours."
    else
      redirect_to training_path, alert: "Something went wrong: #{@enrollment.errors.full_messages.join(', ')}"
    end
  end

  private

  def enrollment_params
    params.permit(:first_name, :last_name, :email, :phone, :program, :experience, :message)
  end
end
