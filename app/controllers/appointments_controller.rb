require 'securerandom'
class AppointmentsController < ApplicationController
  after_action :verify_authorized, except: :index
  layout 'public', only: [:type_of_shoots, :booking, :new_customer]
  after_action :verify_policy_scoped, only: :index
  layout :determine_layout
  before_action :set_appointments, :set_url, only: [:upcoming, :past, :index, :cancel, :cancel_booking, :in_progress]
  skip_before_action :authenticate_user!, only: [:booking, :available_hours, :selected_date,
                                                 :new_customer, :cancel_booking, :cancel, :create, :thank_you, :edit,
                                                 :update, :type_of_shoots,:select_price]

  def upcoming
    authorize Appointment
    @appointments = upcoming_appointment
    @recent_notes = fetch_recent_notes # Add this line
    respond_to_format
  end

  def in_progress
    authorize Appointment
    @appointments = in_progress_appointments
    @recent_notes = fetch_recent_notes # Add this line
    respond_to_format
  end

  def past
    authorize Appointment
    @appointments = past_appointment
    @recent_notes = fetch_recent_notes # Add this line
    respond_to_format
  end

  def index
    authorize Appointment
    @appointments = today_appointment
    @recent_notes = fetch_recent_notes # Add this line
    respond_to_format
  end

  def booking
    authorize Appointment
    @studios = Studio.active
    if params[:id].present?
      @appointment = Appointment.find(params[:id])
      build_questions_for_booking(@appointment)
    elsif params[:price_id].present?
      @appointment = Appointment.new(price: Price.find_by(id: params[:price_id]))
      build_questions_for_booking(@appointment)
    else
      redirect_to type_of_shoots_appointments_path
    end
  end

  def edit
    authorize Appointment
    @appointment = Appointment.find(params[:id])

    # For public users, redirect to the booking flow with the appointment ID
    unless user_signed_in?
      redirect_to booking_appointments_path(id: @appointment.id)
      return
    end

    # For authenticated users, use the regular edit form
    build_questions_for_booking(@appointment)

    # Render the appropriate layout
    render layout: user_signed_in? ? 'application' : 'public'
  end


  def new_customer
    authorize Appointment

    if params[:id].present?
      # Editing an existing appointment
      @appointment = Appointment.find(params[:id])

      # If date parameter is provided, update the start_time
      if params[:date].present?
        @appointment.start_time = params[:date]
      end
    else
      # Creating a new appointment
      @appointment = Appointment.new(price: Price.find_by(id: params[:price_id]))

      # Set start_time for new appointments
      if params[:date].present?
        @appointment.start_time = params[:date]
      end
    end

    # Set location from params if provided
    if params[:location].present?
      @appointment.location = params[:location]
    end

    # Build the questions
    build_questions_for_booking(@appointment)
  end

  def available_hours
    authorize Appointment
    @available_hours = available_slots(params[:location])

    # Set up the appointment (either existing or new)
    if params[:id].present?
      @appointment = Appointment.find(params[:id])
    else
      @appointment = Appointment.new(price: Price.find_by(id: params[:price_id]))
    end

    build_questions_for_booking(@appointment)
  end

  def update
    authorize Appointment
    @appointment = Appointment.find(params[:id])

    # Keep track of original status for potential notifications
    original_status = @appointment.status
    has_existing_sales = @appointment.sales.exists?

    if @appointment.update(appointment_params)
      # Only send notification if a public user is updating
      unless user_signed_in?
        # Only send 'edited' notification if the appointment was previously active
        if original_status
          AppointmentNotificationJob.perform_later(@appointment, 'edited')
          AppointmentUpdateSmsJob.perform_later(@appointment.id, 'updated')

        end

        # Redirect to thank you page with a flag indicating if payment is needed
        redirect_to thank_you_appointments_path(
          appointment_id: @appointment.id,
          payment_needed: (!@appointment.payment_status && @appointment.price_id.present? && !has_existing_sales)
        ), notice: "Your appointment has been updated successfully."
      else
        if original_start_time != @appointment.start_time
          AppointmentUpdateSmsJob.perform_later(@appointment.id, 'updated')
        end
        redirect_to @appointment
      end
    else
      if user_signed_in?
        render :edit, status: :unprocessable_entity
      else
        build_questions_for_booking(@appointment)
        render :new_customer, status: :unprocessable_entity
      end
    end
  end

  def cancel_booking
    authorize Appointment
    @appointment = Appointment.find(params[:id])
  end

  def cancel
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    if @appointment.update(status: false)
      AppointmentNotificationJob.perform_later(@appointment, 'canceled')
      AppointmentUpdateSmsJob.perform_later(@appointment.id, 'cancelled')

      redirect_to appointments_path, notice: 'Booking was successfully cancelled.'
    else
      redirect_to appointments_path, alert: 'Failed to cancel the booking.'
    end
  end

  def available_slots(location)
    utc_date = Time.zone.parse(params[:date])
    date = utc_date.in_time_zone(Time.zone)

    # Fetch all bookings for the selected date, excluding the current appointment if editing
    booked_slots_query = Appointment.where(location: location, status: true, start_time: date.beginning_of_day..date.end_of_day)

    # If we're editing an appointment, exclude its current slot from the booked slots
    if params[:id].present?
      current_appointment = Appointment.find(params[:id])
      booked_slots_query = booked_slots_query.where.not(id: current_appointment.id)
    end

    booked_slots = booked_slots_query.pluck(:start_time)

    # Define your available slots (e.g., from 9am to 6pm)
    available_slots = generate_time_slots.reject { |slot| booked_slots.include?(slot) }

    # For today, filter out past times
    if date.to_date == Time.zone.today
      current_time = Time.zone.now
      available_slots = available_slots.reject { |slot| slot < current_time }
    end

    available_slots.map do |slot|
      format_time(slot)
    end
  end


  def show
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    @appointment_note = AppointmentNote.new # For new note form
    @notes_by_type = @appointment.appointment_notes.includes(:created_by)
                                 .group_by(&:note_type)
  end

  def add_note
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    @appointment_note = @appointment.appointment_notes.build(appointment_note_params)
    @appointment_note.created_by = current_user
    
    if @appointment_note.save
      redirect_to @appointment, notice: 'Internal note added successfully.'
    else
      redirect_to @appointment, alert: 'Failed to add note.'
    end
  end
  
  # Action to delete notes  
  def remove_note
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    @note = @appointment.appointment_notes.find(params[:note_id])
    
    if @note.destroy
      redirect_to @appointment, notice: 'Note removed successfully.'
    else
      redirect_to @appointment, alert: 'Failed to remove note.'
    end
  end

  def toggle_note_action
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    @note = @appointment.appointment_notes.find(params[:note_id])
    
    if params[:actioned] == 'true' || params[:actioned] == true
      @note.update!(
        actioned: true,
        actioned_at: Time.current,
        actioned_by: current_user
      )
      
      render json: { 
        success: true, 
        actioned: true, 
        message: "Note marked as actioned by #{current_user.email}"
      }
    else
      @note.update!(
        actioned: false,
        actioned_at: nil,
        actioned_by: nil
      )
      
      render json: { 
        success: true, 
        actioned: false, 
        message: "Note marked as pending"
      }
    end
  rescue => e
    render json: { success: false, error: e.message }, status: 422
  end

  def mark_no_show
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    @appointment.update(no_show: true)
    redirect_to appointments_path, notice: 'Appointment marked as no-show.'
  end

  def new
    authorize Appointment
    @appointment = Appointment.new
    @studios = Studio.active
    build_questions_for(@appointment)
  end

  def type_of_shoots
    authorize Appointment
    @shoot_types = Price.where(still_valid: true).select(:shoot_type, :icon).distinct

  end

  def select_price
    authorize Appointment
    @shoot_type = params[:shoot_type]
    @prices = Price.where(shoot_type: @shoot_type, still_valid: true ).order(:outfit)
  end


  # def create
  #   authorize Appointment
  #   @appointment = Appointment.new(appointment_params)
  #   @appointment.set_defaults(current_user)
  #   @appointment.uuid = SecureRandom.uuid
  #   if @appointment.save
  #     session.delete(:form_data)
  #     if user_signed_in?
  #       redirect_to appointments_path, notice: 'Appointment was successfully created.'
  #     else
  #       @appointment.schedule_policy_email
  #       @appointment.schedule_reminder_email
  #       AppointmentNotificationJob.perform_later(@appointment, 'created')
  #       redirect_to thank_you_appointments_path(appointment_id: @appointment.id), notice: "Your appointment has been booked successfully."
  #     end
  #   else
  #     if user_signed_in?
  #       build_questions_for(@appointment) # Rebuild questions if save fails
  #       render :new, status: :unprocessable_entity
  #     else
  #       build_questions_for_booking(@appointment)
  #       render :new_customer, status: :unprocessable_entity
  #     end
  #   end
  # end

  def create
    authorize Appointment

    service = AppointmentCreationService.new(appointment_params, current_user, session)
    result = service.call

    if result[:success]
      session.delete(:form_data)

      # session.delete(:referral_code)


      if user_signed_in?
        redirect_to appointments_path, notice: 'Appointment was successfully created.'
      else
        redirect_to thank_you_appointments_path(appointment_id: result[:appointment].id)
      end
    else
      @appointment = result[:appointment]

      if user_signed_in?
        build_questions_for(@appointment)
        @studios = Studio.active
        render :new, status: :unprocessable_entity
      else
        build_questions_for_booking(@appointment)
        @studios = Studio.active
        render :new_customer, status: :unprocessable_entity
      end
    end
  end

  def customer_pictures
    authorize Appointment
    render_photos(:customer_pictures)
  end

  def photo_inspirations
    authorize Appointment
    render_photos(:photo_inspirations)
  end


  def thank_you
    authorize Appointment
    @appointment = Appointment.find(params[:appointment_id])
  end



  private

  def appointment_note_params
    params.require(:appointment_note).permit(:content, :note_type, :title, :priority)
  end

  def appointment_params
    params.require(:appointment).permit(
      :name,
      :email,
      :start_time,
      :end_time,
      :location,
      :price_id,
      :studio_id,
      customer_pictures: [],
      photo_inspirations: [],
      questions_attributes: [:id, :question, :answer, :_destroy],
      appointment_notes_attributes: [:id, :content, :note_type, :title, :priority, :_destroy]

    )
  end

  def fetch_recent_notes
    # Get appointments within +3 to -3 days from today
    date_range = 3.days.ago.beginning_of_day..3.days.from_now.end_of_day
    
    base_query = AppointmentNote.joins(:appointment)
                                .includes(:appointment, :created_by, :actioned_by)
    
    # Apply location-based filtering based on user role
    location_filtered_query = if current_user.admin? || current_user.manager? || current_user.super_admin?
                                # Admins and managers see all notes
                                base_query
                              else
                                case current_user.role
                                when 'ikeja'
                                  base_query.where("appointments.location ILIKE ?", "%ikeja%")
                                when 'surulere'
                                  base_query.where("appointments.location ILIKE ?", "%surulere%")
                                when 'ajah'
                                  base_query.where("appointments.location ILIKE ? OR appointments.location ILIKE ?", '%Ajah%', '%Ilaje%')
                                else
                                  base_query.none # No access for other roles
                                end
                              end
    
    # Get two sets of notes and combine them
    # 1. All unactioned notes (regardless of date)
    unactioned_notes = location_filtered_query.where(actioned: false)
    
    # 2. All notes from ±3 days (both actioned and unactioned)
    recent_notes = location_filtered_query.where(appointments: { start_time: date_range })
    
    # Combine and remove duplicates, then order by priority and date
    combined_notes = (unactioned_notes.to_a + recent_notes.to_a).uniq
    
    # Sort by priority (high first), then by actioned status (pending first), then by creation date
    combined_notes.sort_by do |note|
      [
        -note.priority,                    # High priority first (3, 2, 1)
        note.actioned? ? 1 : 0,           # Unactioned first (false=0, true=1)
        -note.created_at.to_i             # Most recent first
      ]
    end.first(15) # Limit to 15 most important notes
   end

  # def appointment_params
  #   params.require(:appointment).permit(
  #     :name, :email, :start_time, :studio_id,
  #     questions_attributes: [:id, :question, :answer, :_destroy]
  #   )
  # end

  def in_progress_appointments
    # Find appointments that:
    # 1. Have an associated photoshoot
    # 2. The photoshoot status is NOT 'Sent'
    # 3. The appointment was in the past (already completed)
    appointments = policy_scope(Appointment)
                    .includes(:questions, :photo_shoot)
                    .joins(:photo_shoot)
                    .left_joins(:galleries)
                    .where('appointments.start_time < ?', Time.zone.now)
                    .where('appointments.start_time >= ?', 30.days.ago)
                    .where(appointments: { status: true })
                    .where('photo_shoots.status != ? OR galleries.id IS NULL', 'Sent')
                    .order(:start_time)


    if params[:query].present?
      appointments = appointments.global_search(params[:query])
    end

    # Always return paginated results, even if empty
    appointments.page(params[:page])
  end


  def render_photos(photo_type)
    @appointment = Appointment.find(params[:id])
    @pictures = @appointment.send(photo_type)

    if @pictures.attached?
      render photo_type
    else
      redirect_to appointment_path(@appointment), notice: "No #{photo_type.to_s.humanize.downcase} attached."
    end
  end


  def build_questions_for(appointment)
    if appointment.questions.empty?
      # Assuming you want to build a set of default questions
      Question::QUESTIONS_NEW.each do |question_text|
        appointment.questions.build(question: question_text)
      end
    end
  end

  def build_questions_for_booking(appointment)
    if appointment.questions.empty?
      # Assuming you want to build a set of default questions
      Question::QUESTIONS.each do |question_text|
        appointment.questions.build(question: question_text)
      end
    end
  end



  def format_location(data)
    if data == "KM 22 Lekki Epe Express way , Ilaje Bus Stop Lagos"
      "Ajah"
    elsif data == "115A bode thomas street, Surulere Lagos"
      "Surulere"
    elsif data == "66 Adeniyi Jones , Ikeja Lagos"
      "Ikeja"
    end
  end

  # def data_already_exists?(api_data)
  #   Appointment.exists?(uuid: api_data[:uuid])
  # end

  # def save_data_to_database(api_datas)
  #   api_datas.each do |api_data|
  #     unless data_already_exists?(api_data)
  #       Appointment.create!(uuid: api_data[:uuid], name: api_data[:name], email: api_data[:email],
  #                           start_time: api_data[:start_time], end_time: api_data[:end_time], location: api_data[:location],
  #                           questions_attributes: api_data[:question])
  #     end
  #   end
  # end

  def past_appointment
    appointments = policy_scope(Appointment).includes(:questions).past

    if params[:query].present?
      appointments = appointments.global_search(params[:query])
    end

    appointments.page(params[:page]) if appointments.present?
  end

  def today_appointment
    appointments = policy_scope(Appointment).includes(:questions)
                                            .today
                                            .order(:start_time)

    if params[:query].present?
      appointments = appointments.global_search(params[:query])
    end

    appointments.page(params[:page]) if appointments.present?
  end

  def upcoming_appointment
    appointments = policy_scope(Appointment).includes(:questions).upcoming.order(:start_time)

    if params[:query].present?
      appointments = appointments.global_search(params[:query])
    end

    appointments.page(params[:page]) if appointments.present?
  end

  def set_appointments
    @appointments = policy_scope(Appointment)
  end

  def set_url
    @url = request.url.split('/').last
  end

  # Common respond_to block
  def respond_to_format
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "appointment_table", locals: { appointments: @appointments }, formats: [:html] }
    end
  end

  def generate_time_slots
    date = Date.parse(params[:date])
    
    # Check if this is a newborn package
    is_newborn_session = false
    if params[:price_id].present?
      price = Price.find_by(id: params[:price_id])
      is_newborn_session = price&.shoot_type&.downcase&.include?('newborn')
    end
    
    if is_newborn_session
      # No weekend bookings for newborn sessions
      return [] if date.saturday? || date.sunday?
      
      # Newborn sessions: 9:30 AM to 12:30 PM only (weekdays only)
      start_time = Time.zone.parse("#{date} 09:30")
      end_time = Time.zone.parse("#{date} 12:30")
    elsif date.sunday?
      # Regular Sunday hours
      start_time = Time.zone.parse("#{date} 12:30")
      end_time = Time.zone.parse("#{date} 16:30")
    else
      # Regular weekday hours
      start_time = Time.zone.parse("#{date} 09:30")
      end_time = Time.zone.parse("#{date} 16:30")
    end
  
    (start_time.to_i..end_time.to_i).step(1.hour).map { |time| Time.zone.at(time) }
  end

  def format_time(time)
    hours = time.hour
    minutes = time.min
    formatted_time = "#{hours % 12 == 0 ? 12 : hours % 12}:#{minutes.to_s.rjust(2, '0')} #{hours < 12 ? 'AM' : 'PM'}"
    formatted_time
  end

  def load_available_slots(date)
    booked_slots = Appointment.where(start_time: date.beginning_of_day..date.end_of_day).pluck(:start_time)
    @available_slots = generate_time_slots.reject { |slot| booked_slots.include?(slot) }
    @available_slots = @available_slots.map { |slot| format_time(slot) }
  end

  def determine_layout
    public_actions = ['type_of_shoots', 'booking', 'new_customer', 'available_hours', 'selected_date', 'cancel_booking', 'thank_you', 'edit', 'select_price']

    if public_actions.include?(action_name)
      'public'
    else
      'application'
    end
  end

end
