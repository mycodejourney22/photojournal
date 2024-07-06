class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, only: :calendly
  protect_from_forgery except: :calendly
  skip_before_action :verify_authenticity_token, only: :calendly

  def calendly
    event = permit_params[:event]
    payload = permit_params[:payload]

    case event
    when 'invitee.created'
      handle_invitee_created(payload)
    when 'invitee.canceled'
      handle_invitee_canceled(payload)
    else
      render json: { message: 'Event not supported' }, status: :unprocessable_entity
    end
    render json: { message: 'Webhook received successfully' }, status: :ok
  end

  private

  def permit_params
    params.require(:webhook).permit(
      :event,
      payload: [
        :event,
        :created_at,
        :email,
        :first_name,
        :last_name,
        :name,
        :reschedule_url,
        :cancel_url,
        { questions_and_answers: [:question, :answer] },
        { scheduled_event: [:start_time, :end_time, { location: [:location] }] }
      ]
    )
  end

  def extract_uuid(url)
    uuid_pattern = /[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}/i
    url.match(uuid_pattern)[0]
  end

  def data_already_exists?(data)
    Appointment.exists?(uuid: data[:uuid])
  end

  def appointment_data(data)
    {
      uuid: extract_uuid(data[:event]),
      name: data["name"],
      email: data["email"],
      start_time: data.dig(:scheduled_event, :start_time),
      end_time: data.dig(:scheduled_event, :end_time),
      location: format_location(data.dig(:scheduled_event, :location, :location)),
      questions: data["questions_and_answers"]
    }
  end

  def handle_invitee_created(payload)
    appointment_data = appointment_data(payload)

    unless data_already_exists?(appointment_data)
      Appointment.create!(uuid: appointment_data[:uuid],
                          name: appointment_data[:name],
                          email: appointment_data[:email],
                          start_time: appointment_data[:start_time],
                          end_time: appointment_data[:end_time],
                          location: appointment_data[:location],
                          questions_attributes: appointment_data[:questions])
    end
  end

  def handle_invitee_canceled(payload)
    appointment_data = appointment_data(payload)
    puts appointment_data
    appointment = Appointment.find_by(uuid: appointment_data[:uuid])
    appointment&.update(status: false)
  end

  def format_location(data)
    case data
    when "KM 22 Lekki Epe Express way , Ilaje Bus Stop Lagos"
      "Ajah"
    when "115A bode thomas street, Surulere Lagos"
      "Surulere"
    when "66 Adeniyi Jones , Ikeja Lagos"
      "Ikeja"
    else
      data # return the original data if no match is found
    end
  end
end
