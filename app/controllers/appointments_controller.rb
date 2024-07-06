require 'securerandom'
class AppointmentsController < ApplicationController
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    authorize Appointment
    @appointments = policy_scope(Appointment)
                    .where('start_time >= ?', Time.zone.now.beginning_of_day)
                    .order(:start_time)
                    .select { |appointment|
                      !appointment.no_show &&
                      appointment.status
                    }
                    .group_by { |appointment| appointment.start_time.to_date }
    @heading = "#{Date.today.strftime("%A, %d %B %Y") }"
    respond_to do |format|
      format.html # Follow regular flow of Rails
      format.text { render partial: "appointment_table", locals: { appointments: @appointments }, formats: [:html] }
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
      redirect_to appointments_path, notice: 'Appointment was successfully created.'
    else
      build_questions_for(@appointment) # Rebuild questions if save fails
      render :new, status: :unprocessable_entity
    end
  end

  private

  def appointment_params
    params.require(:appointment).permit(:name, :email, :start_time, :end_time, :location,
                                                           questions_attributes: [:id, :question,:answer,:_destroy])
  end

  def build_questions_for(appointment)
    Question::QUESTIONS.each do |question_content|
      appointment.questions.build(question: question_content)
    end
  end


  def header_details
    {
      Authorization: "Bearer #{ENV.fetch('CALENDLY_BEARER_TOKEN')}",
      'Content-Type': 'application/json'
    }
  end

  def all_booking_params(end_of_day_iso8601, beginning_of_day_iso8601)
    { organization: 'https://api.calendly.com/organizations/4459d3df-3d64-4cd5-a7c7-ee529a88e257',
      sort: "start_time:desc", status: 'active',
      max_start_time: end_of_day_iso8601, min_start_time: beginning_of_day_iso8601 }
  end

  def make_request(url, header, arr)
    response = RestClient.get(url, header)
    resp = JSON.parse(response.body)['collection']
    resp.each do |res|
      arr << all_booking_extract(res)
    end
  end

  def all_booking_extract(res)
    { uuid: res["uri"], start_time: res["start_time"], end_time: res["end_time"], location: res["location"]["location"] }
  end

  def end_of_day
    end_of_day = Time.now.end_of_day
    end_of_day.strftime('%Y-%m-%dT%H:%M:%S.%6NZ')
  end

  def start_of_day
    beginning_of_day = Time.now.beginning_of_day
    beginning_of_day.strftime('%Y-%m-%dT%H:%M:%S.%6NZ')
  end

  def fetch_all_bookings
    arr = []
    url = "https://api.calendly.com/scheduled_events"
    params = all_booking_params(end_of_day, start_of_day)
    full_url = "#{url}?#{URI.encode_www_form(params)}"
    make_request(full_url, header_details, arr)
    arr
  rescue RestClient::ExceptionWithResponse => e
    puts "Error fetching bookings: #{e.response}"
    []
  end

  def extract_uuid(url)
    uuid_pattern = /[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}/i
    url.match(uuid_pattern)[0]
  end

  def customer_info
    arr = fetch_all_bookings
    new_arr = []
    headers = header_details
    arr.each do |info|
      url = "https://api.calendly.com/scheduled_events/#{extract_uuid(info[:uuid])}/invitees"
      params = { status: 'active' }
      full_url = "#{url}?#{URI.encode_www_form(params)}"
      response = RestClient.get(full_url, headers)
      resp = JSON.parse(response.body)['collection']
      new_arr << {
        uuid: extract_uuid(info[:uuid]),
        name: resp.first["name"], question: resp.first["questions_and_answers"],
        email: resp.first["email"], start_time: info[:start_time],
        end_time: info[:end_time], location: format_location(info[:location])
      }
    end
    save_data_to_database(new_arr)
    new_arr
  rescue RestClient::ExceptionWithResponse => e
    puts "Error fetching bookings: #{e.response}"
    []
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

  def data_already_exists?(api_data)
    Appointment.exists?(uuid: api_data[:uuid])
  end

  def save_data_to_database(api_datas)
    api_datas.each do |api_data|
      unless data_already_exists?(api_data)
        Appointment.create!(uuid: api_data[:uuid], name: api_data[:name], email: api_data[:email],
                            start_time: api_data[:start_time], end_time: api_data[:end_time], location: api_data[:location],
                            questions_attributes: api_data[:question])
      end
    end
  end

end
