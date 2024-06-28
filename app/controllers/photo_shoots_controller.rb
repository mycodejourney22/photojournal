class PhotoShootsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  before_action :set_appointment, except: [:index, :notes]

  def index
    authorize PhotoShoot
    @photoshoots = policy_scope(PhotoShoot).all.order(date: :desc)
    @photoshoots = PhotoShoot.global_search(params[:query]) if params[:query].present?
    @heading = "#{Date.today.strftime("%A, %d %B %Y") }"
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "table", locals: {photoshoots: @photoshoots}, formats: [:html] }
    end
  end

  def new
    authorize PhotoShoot
    @photo_shoot = @appointment.build_photo_shoot
    @photo_shoot.build_sale
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
    @photo_shoot.sale.date = @photo_shoot.date
    @photo_shoot.sale.customer_service_officer_name = Staff.find(@photo_shoot.customer_service_id).name
    @photo_shoot.sale.customer_name = @photo_shoot.appointment.name
    @photo_shoot.sale.location = determine_location(current_user)
    @photo_shoot.sale.product_service_name = "PhotoShoot"
    if @photo_shoot.save
      redirect_to appointments_path, notice: 'PhotoShoot was successfully created.'
    else
      render :new
    end
  end

  def notes
    authorize PhotoShoot
    @photoshoots = policy_scope(PhotoShoot).where.not(notes: "")
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
    @photo_shoot.assign_attributes(photo_shoot_params)
    appointment = Appointment.find(params[:appointment_id])
    @photo_shoot.appointment = appointment
    build_sales(@photo_shoot)
    if @photo_shoot.save
      redirect_to photo_shoots_path, notice: 'PhotoShoot and Sale were successfully updated.'
    else
      render :edit
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  def photo_shoot_params
    params.require(:photo_shoot).permit(
      :date,
      :photographer_id,
      :editor_id,
      :customer_service_id,
      :notes,
      :number_of_selections,
      :status,
      :type_of_shoot,
      :number_of_outfits,
      :date_sent,
      sale_attributes: [
        :amount_paid,
        :payment_method,
        :payment_type,
        :reference
      ]
    )
  end

  def determine_location(user)
    case user.role
    when 'admin'
      'general'
    when 'ajah'
      'ajah'
    when 'ikeja'
      'ikeja'
    when 'surulere'
      'surulere'
    else
      'unknown'
    end
  end

  def build_sales(photo_shoot)
    photo_shoot.sale.date = photo_shoot.date
    photo_shoot.sale.customer_service_officer_name = Staff.find(photo_shoot.customer_service_id).name
    photo_shoot.sale.customer_name = photo_shoot.appointment.name
    photo_shoot.sale.location = determine_location(current_user)
    photo_shoot.sale.product_service_name = "PhotoShoot"
  end
end
