require 'securerandom'
class AppointmentsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  before_action :set_appointments, :set_url, only: [:upcoming, :past, :index, :cancel, :cancel_booking]
  skip_before_action :authenticate_user!, only: [:booking, :available_hours, :selected_date,
                                                 :new_customer, :cancel_booking, :cancel, :create, :thank_you, :edit, :update]


  def upcoming
    authorize Appointment
    @appointments = upcoming_appointment
    respond_to_format
  end

  def past
    authorize Appointment
    @appointments = past_appointment
    respond_to_format
  end

  def index
    authorize Appointment
    @appointments = today_appointment
    respond_to_format
  end

  def booking
    authorize Appointment
    @appointment = Appointment.new
    Question::QUESTIONS.each do |q|
      @appointment.questions.build(question: q)
    end
  end

  def edit
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    Question::QUESTIONS.each do |q|
      @appointment.questions.build(question: q)
    end
  end
  def new_customer
    authorize Appointment
    @appointment = params[:id] ? Appointment.find(params[:id]) : Appointment.new
    # raise
    # Only build questions if they don't already exist
    if @appointment.questions.empty?
      Question::QUESTIONS.each do |q|
        @appointment.questions.build(question: q)
      end
    end
  end

  def available_hours
    authorize Appointment
    @available_hours = available_slots(params[:location])
    @appointment = params[:id] ? Appointment.find(params[:id]) : Appointment.new
    Question::QUESTIONS.each do |q|
      @appointment.questions.build(question: q)
    end
  end

  def update
    authorize Appointment
    @appointment = Appointment.find(params[:id])
    if @appointment.update(appointment_params)
      if user_signed_in?
        redirect_to @appointment, notice: 'Appointment was successfully updated.'
      else
        AppointmentNotificationJob.perform_later(@appointment, 'edited')
        redirect_to thank_you_appointments_path(appointment_id: @appointment.id), notice: "Your appointment has been updated successfully."
      end
    else
      render :edit, status: :unprocessable_entity
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
      redirect_to appointments_path, notice: 'Booking was successfully cancelled.'
    else
      redirect_to appointments_path, alert: 'Failed to cancel the booking.'
    end
  end

  def available_slots(location)
    # You can adjust logic here to return different time slots based on the day
    # date = params[:date].to_date
    utc_date = Time.zone.parse(params[:date])
    date = utc_date.in_time_zone(Time.zone)
    # Fetch all bookings for the selected date
    booked_slots = Appointment.where(location: location, start_time: date.beginning_of_day..date.end_of_day).pluck(:start_time)

    # Define your available slots (e.g., from 9am to 6pm)
    available_slots = generate_time_slots.reject { |slot| booked_slots.include?(slot) }

    available_slots.map do |slot|
      format_time(slot)
    end
  end


  def show
    authorize Appointment
    @appointment = Appointment.find(params[:id])
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
    build_questions_for(@appointment)
  end


  def create
    authorize Appointment
    @appointment = Appointment.new(appointment_params)
    @appointment.uuid = SecureRandom.uuid
    if @appointment.save
      if user_signed_in?
        redirect_to appointments_path, notice: 'Appointment was successfully created.'
      else
        AppointmentNotificationJob.perform_later(@appointment, 'created')
        redirect_to thank_you_appointments_path(appointment_id: @appointment.id), notice: "Your appointment has been booked successfully."
      end
    else
      build_questions_for(@appointment) # Rebuild questions if save fails
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
    authorize Appointment
    @appointment = Appointment.find(params[:appointment_id])
  end

  private

  def appointment_params
    params.require(:appointment).permit(:name, :email, :start_time, :end_time, :location,
                                                           questions_attributes: [:id, :question,:answer,:_destroy])
  end

  def build_questions_for(appointment)
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
    appointments = policy_scope(Appointment).includes(:questions)
                                            .where(start_time: 14.days.ago.beginning_of_day..Time.zone.now.beginning_of_day)
                                            .order(start_time: :desc)
    appointments = policy_scope(Appointment).global_search(params[:query]) if params[:query].present?
    appointments.page(params[:page]) if appointments.present?
  end

  def today_appointment
    appointments = policy_scope(Appointment).includes(:questions)
                                            .where(start_time: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
                                            .where(no_show: false, status: true)
                                            .order(:start_time)

    appointments = policy_scope(Appointment).global_search(params[:query]) if params[:query].present?
    appointments.page(params[:page]) if appointments.present?
  end

  def upcoming_appointment
    appointments = policy_scope(Appointment).includes(:questions).where('start_time > ?', Time.zone.now.end_of_day)
                                            .where(no_show: false, status: true)
                                            .order(:start_time)
    appointments = today_appointments.global_search(params[:query]) if params[:query].present?
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
    # Assuming appointments are hourly from 9 AM to 6 PM
    date = Date.parse(params[:date])
    if date.sunday?
      start_time = Time.zone.parse("12:30")
    else
      start_time = Time.zone.parse("09:30")
    end
    end_time = Time.zone.parse("17:30")
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
end
