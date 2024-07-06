# lib/tasks/fetch_calendly_events.rake

namespace :calendly do
  desc "Fetch events from Calendly"
  task fetch_events: :environment do
    require 'rest-client' # or any other HTTP client gem you're using

    def header_details
      {
        Authorization: "Bearer #{ENV.fetch('CALENDLY_BEARER_TOKEN')}",
        'Content-Type': 'application/json'
      }
    end

    def all_booking_params
      {
        organization: 'https://api.calendly.com/organizations/4459d3df-3d64-4cd5-a7c7-ee529a88e257',
        sort: "start_time:desc",
        status: 'active',
        count: 100
      }
    end

    def make_request(url, header, arr)
      response = RestClient.get(url, header)
      resp = JSON.parse(response.body)['collection']
      resp.each do |res|
        arr << all_booking_extract(res)
      end
    end

    def all_booking_extract(res)
      {
        uuid: res["uri"],
        start_time: res["start_time"],
        end_time: res["end_time"],
        location: res["location"]["location"]
      }
    end

    def fetch_all_bookings
      arr = []
      url = "https://api.calendly.com/scheduled_events"
      params = all_booking_params
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
          name: resp.first["name"],
          question: resp.first["questions_and_answers"],
          email: resp.first["email"],
          start_time: info[:start_time],
          end_time: info[:end_time],
          location: format_location(info[:location])
        }
      end
      save_data_to_database(new_arr)
      new_arr
    rescue RestClient::ExceptionWithResponse => e
      puts "Error fetching bookings: #{e.response}"
      []
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
        "Unknown Location"
      end
    end

    def data_already_exists?(api_data)
      Appointment.exists?(uuid: api_data[:uuid])
    end

    def save_data_to_database(api_datas)
      api_datas.each do |api_data|
        unless data_already_exists?(api_data)
          begin
            Appointment.create!(
              uuid: api_data[:uuid],
              name: api_data[:name],
              email: api_data[:email],
              start_time: api_data[:start_time],
              end_time: api_data[:end_time],
              location: api_data[:location],
              questions_attributes: api_data[:question]
            )
            puts "Successfully saved appointment with UUID: #{api_data[:uuid]}"
          rescue ActiveRecord::RecordInvalid => e
            puts "Failed to save appointment with UUID: #{api_data[:uuid]}"
            puts "Error: #{e.message}"
          end
        else
          puts "Appointment with UUID: #{api_data[:uuid]} already exists"
        end
      end
    end

    # Execute the customer_info method to fetch and save events
    customer_info
  end
end
