# app/controllers/refund_requests_controller.rb
class RefundRequestsController < ApplicationController
  before_action :set_appointment, only: [:new, :create]
  before_action :set_refund_request, only: [:show, :approve, :decline, :process_refund]
  skip_before_action :authenticate_user!, only: [:new, :create, :confirmation]
  before_action :authorize_admin, only: [:index, :approve, :decline, :process_refund]

  layout :determine_layout

  # GET /refund_requests
  # Admin view of all refund requests
  def index
    @refund_requests = RefundRequest.includes(:appointment).order(created_at: :desc).page(params[:page])

    # Filter by status if specified
    if params[:status].present? && RefundRequest.statuses.key?(params[:status])
      @refund_requests = @refund_requests.where(status: params[:status])
    end

    # Filter by location if user isn't admin
    unless current_user&.admin? || current_user&.super_admin?
      if current_user&.ikeja?
        @refund_requests = @refund_requests.joins(:appointment).where("appointments.location ILIKE ?", "%ikeja%")
      elsif current_user&.surulere?
        @refund_requests = @refund_requests.joins(:appointment).where("appointments.location ILIKE ?", "%surulere%")
      elsif current_user&.ajah?
        @refund_requests = @refund_requests.joins(:appointment).where("appointments.location ILIKE ? OR appointments.location ILIKE ?", "%ajah%", "%ilaje%")
      end
    end
  end

  # GET /refund_requests/new
  # Public form for customers
  def new
    @refund_request = @appointment.refund_requests.build

    # Calculate max refund amount based on sales
    @max_refund = @appointment.sales.where(void: false).where("amount_paid > 0").sum(:amount_paid)

    # Check if appointment exists and has been paid for
    if @appointment.nil?
      redirect_to public_home_path, alert: "Appointment not found."
      return
    elsif @max_refund <= 0
      redirect_to public_home_path, alert: "This appointment has no payment records to refund."
      return
    end

    # Pre-fill some fields
    @refund_request.refund_amount = @max_refund
  end

  # POST /refund_requests
  def create
    @refund_request = @appointment.refund_requests.build(refund_request_params)
    @max_refund = @appointment.sales.where(void: false).sum(:amount_paid)

    if @refund_request.save
      # Send notification email to admin
      AdminMailer.new_refund_request(@refund_request).deliver_later

      # Send confirmation email to customer
      CustomerMailer.refund_request_received(@refund_request).deliver_later

      redirect_to confirmation_refund_requests_path(token: @refund_request.id)
    else
      render :new
    end
  end

  # GET /refund_requests/confirmation
  def confirmation
    # Just show confirmation page
  end

  # GET /refund_requests/:id
  # Admin view of a specific request
  def show
    authorize @refund_request
  end

  # PATCH /refund_requests/:id/approve
  def approve
    authorize @refund_request

    if @refund_request.pending?
      @refund_request.status = :approved
      @refund_request.processed_by = current_user
      @refund_request.processed_at = Time.current
      @refund_request.admin_notes = params[:admin_notes] if params[:admin_notes].present?

      if @refund_request.save
        # Send approval email to customer
        CustomerMailer.refund_request_approved(@refund_request).deliver_later

        redirect_to refund_requests_path, notice: "Refund request has been approved and a negative sale has been created."
      else
        redirect_to refund_request_path(@refund_request), alert: "Could not approve refund request: #{@refund_request.errors.full_messages.join(', ')}"
      end
    else
      redirect_to refund_request_path(@refund_request), alert: "This refund request cannot be approved in its current state."
    end
  end

  # PATCH /refund_requests/:id/decline
  def decline
    authorize @refund_request

    if @refund_request.pending?
      @refund_request.status = :declined
      @refund_request.processed_by = current_user
      @refund_request.processed_at = Time.current
      @refund_request.admin_notes = params[:admin_notes] if params[:admin_notes].present?

      if @refund_request.save
        # Send decline email to customer
        CustomerMailer.refund_request_declined(@refund_request).deliver_later

        redirect_to refund_requests_path, notice: "Refund request has been declined."
      else
        redirect_to refund_request_path(@refund_request), alert: "Could not decline refund request: #{@refund_request.errors.full_messages.join(', ')}"
      end
    else
      redirect_to refund_request_path(@refund_request), alert: "This refund request cannot be declined in its current state."
    end
  end

  # PATCH /refund_requests/:id/process_refund
  def process_refund
    authorize @refund_request

    if @refund_request.approved?
      @refund_request.status = :processed
      @refund_request.processed_at = Time.current
      @refund_request.admin_notes = "#{@refund_request.admin_notes}\nProcessed: #{params[:processing_details]}" if params[:processing_details].present?

      if @refund_request.save
        # Send processing confirmation to customer
        CustomerMailer.refund_processed(@refund_request).deliver_later

        redirect_to refund_requests_path, notice: "Refund has been marked as processed and customer has been notified."
      else
        redirect_to refund_request_path(@refund_request), alert: "Could not process refund: #{@refund_request.errors.full_messages.join(', ')}"
      end
    else
      redirect_to refund_request_path(@refund_request), alert: "This refund request must be approved before it can be processed."
    end
  end

  private

  def set_appointment
    if params[:appointment_uuid]
      @appointment = Appointment.find_by(uuid: params[:appointment_uuid])
    elsif params[:appointment_id]
      @appointment = Appointment.find(params[:appointment_id])
    end

    # Handle missing appointment
    if @appointment.nil?
      redirect_to public_home_path, alert: "Appointment not found."
    end
  end

  def set_refund_request
    @refund_request = RefundRequest.find(params[:id])
  end

  def refund_request_params
    params.require(:refund_request).permit(
      :reason, :refund_amount, :customer_notes,
      :account_name, :account_number, :bank_name
    )
  end

  def authorize_admin
    unless user_signed_in? && (current_user.admin? || current_user.manager? || current_user.super_admin?)
      redirect_to public_home_path, alert: "You are not authorized to access this page."
    end
  end

  def determine_layout
    if user_signed_in?
      'application'
    else
      'public'
    end
  end
end
