class PhotoShootsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  before_action :set_appointment, except: [:index, :upfront, :notes]

  def index
    authorize PhotoShoot
    @photoshoots = policy_scope(PhotoShoot).all.order(created_at: :desc)
    @heading = "#{Date.today.strftime("%A, %d %B %Y") }"
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "table", locals: {photoshoots: @photoshoots}, formats: [:html] }
    end
  end

  def new
    authorize PhotoShoot
    @photo_shoot = @appointment.build_photo_shoot
    @heading = "Add Photoshoot Information for #{@photo_shoot.appointment.name}"
  end

  def show
    authorize PhotoShoot
    @photo_shoot = PhotoShoot.find(params[:id])
    @photographer = Staff.find(@photo_shoot.photographer_id).name
    @editor = Staff.find(@photo_shoot.editor_id).name
    @customer_service = Staff.find(@photo_shoot.customer_service_id).name
    @heading = "#{Date.today.strftime("%A, %d %B %Y") }"
  end

  def create
    authorize PhotoShoot
    @photo_shoot = @appointment.build_photo_shoot(photo_shoot_params)
    if @photo_shoot.save
      redirect_to appointments_path, notice: 'PhotoShoot was successfully created.'
    else
      render :new
    end
  end

  def upfront
    authorize PhotoShoot
    @photoshoots = policy_scope(PhotoShoot).where(payment_type: "Upfront")
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "upfront_table", locals: {photoshoots: @photoshoots}, formats: [:html] }
    end
  end

  def notes
    authorize PhotoShoot
    @photoshoots = policy_scope(PhotoShoot).where.not(notes: nil)
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "notes_table", locals: {photoshoots: @photoshoots}, formats: [:html] }
    end
  end

  def edit
    authorize PhotoShoot
    @photo_shoot = PhotoShoot.find(params[:id])
  end

  def update
    authorize PhotoShoot
    @photo_shoot = PhotoShoot.find(params[:id])
    appointment = Appointment.find(params[:appointment_id])
    @photo_shoot.appointment = appointment
    @photo_shoot.update(photo_shoot_params)
    redirect_to photo_shoots_path
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  def photo_shoot_params
    params.require(:photo_shoot).permit(:date, :photographer_id, :editor_id, :customer_service_id, :number_of_selections,
                                        :status, :type_of_shoot, :number_of_outfits, :date_sent, :payment_total,
                                        :payment_method, :payment_type, :reference)
  end
end
