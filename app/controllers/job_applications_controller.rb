# app/controllers/job_applications_controller.rb
class JobApplicationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :thank_you]
  layout 'public', only: [:new, :create, :thank_you]

  def index
    authorize JobApplication
    @job_applications = policy_scope(JobApplication).recent.page(params[:page])

    if params[:position].present?
      @job_applications = @job_applications.by_position(params[:position])
    end

    if params[:status].present?
      @job_applications = @job_applications.where(status: params[:status])
    end
  end

  def show
    @job_application = JobApplication.find(params[:id])
    authorize @job_application
  end

  def new
    @job_application = JobApplication.new
  end

  def create
    @job_application = JobApplication.new(job_application_params)

    if @job_application.save
      # Send emails
      JobApplicationMailer.hr_notification(@job_application).deliver_later
      JobApplicationMailer.applicant_confirmation(@job_application).deliver_later

      redirect_to thank_you_job_applications_path(ref: @job_application.reference_number)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
    @reference_number = params[:ref]
  end

  def update
    @job_application = JobApplication.find(params[:id])
    authorize @job_application

    if @job_application.update(job_application_params)
      redirect_to @job_application, notice: 'Application updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def download_cv
    @job_application = JobApplication.find(params[:id])
    authorize @job_application

    if @job_application.cv.attached?
      redirect_to rails_blob_path(@job_application.cv, disposition: 'attachment')
    else
      redirect_to @job_application, alert: 'No CV attached.'
    end
  end

  private

  def job_application_params
    params.require(:job_application).permit(
      :name,
      :email,
      :phone,
      :position,
      :portfolio_link,
      :motivation,
      :status,
      :cv,
      portfolio_files: []
    )
  end
end
