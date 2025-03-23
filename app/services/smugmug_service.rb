# app/services/smugmug_service.rb
require 'oauth'
require 'json'

class SmugmugService
  API_BASE_URL = "https://api.smugmug.com/api/v2"

  def initialize(options = {})
    @oauth_token = options[:oauth_token] || ENV['SMUGMUG_OAUTH_TOKEN']
    @oauth_secret = options[:oauth_secret] || ENV['SMUGMUG_OAUTH_SECRET']
    @api_key = options[:api_key] || ENV['SMUGMUG_API_KEY']
    @api_secret = options[:api_secret] || ENV['SMUGMUG_API_SECRET']
    @user = options[:user] || ENV['SMUGMUG_USER']

    # Only check credentials if we need to make actual API calls
    # Skip in development mode if mock mode is enabled
    # unless Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
    #   ensure_credentials_present
    # end
  end

  # Upload images to a gallery
  def upload_gallery(appointment, files)
    # In development, we can use mock mode to skip actual API calls
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_upload_gallery(appointment, files)
    end

    begin
      # 1. Create or find gallery
      gallery = find_or_create_gallery(appointment)

      # If we couldn't create a gallery, return an error
      return { success: false, error: "Failed to create gallery: #{gallery[:error]}" } if gallery[:error].present?

      # 2. Upload each file
      results = {
        success: [],
        failed: []
      }

      files.each do |file|
        result = upload_image_to_gallery(gallery[:uri], file)
        if result[:success]
          results[:success] << { filename: file.original_filename, image_key: result[:image_key] }
        else
          results[:failed] << { filename: file.original_filename, error: result[:error] }
        end
      end

      return {
        success: true,
        gallery_url: gallery[:url],
        gallery_key: gallery[:key],
        results: results
      }
    rescue StandardError => e
      Rails.logger.error("SmugmugService#upload_gallery error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return { success: false, error: e.message }
    end
  end

  # Retrieve a customer's galleries
  def get_customer_galleries(customer)
    # Skip in mock mode
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_get_customer_galleries(customer)
    end

    # This will retrieve all galleries for a specific customer based on our naming convention
    customer_phone = customer.phone_number.gsub(/\D/, '')
    folder_path = folder_path_for_customer(customer)

    response = make_api_request("folder/user/#{@user}#{folder_path}!folders")
    return { success: false, error: response[:error] } unless response[:success]

    # Process the folders (potentially representing different photoshoots)
    galleries = []
    if response[:data][:Folder][:Folders]
      response[:data][:Folder][:Folders].each do |folder|
        # For each photoshoot folder, get the galleries
        folder_response = make_api_request("#{folder[:Uri]}!galleries")
        next unless folder_response[:success]

        if folder_response[:data][:Folder][:Galleries]
          folder_response[:data][:Folder][:Galleries].each do |gallery|
            galleries << {
              title: gallery[:Name],
              url: gallery[:WebUri],
              key: gallery[:NodeID],
              date: gallery[:DateAdded],
              image_count: gallery[:ImageCount]
            }
          end
        end
      end
    end

    return { success: true, galleries: galleries }
  end

  # Generate a share token for a gallery (for customer access)
  def create_share_token(gallery_key, expires_in = 30.days)
    # Skip in mock mode
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_create_share_token(gallery_key, expires_in)
    end

    response = make_api_request(
      "gallery/#{gallery_key}!sharetokens",
      method: :post,
      data: {
        ShareToken: {
          Password: "",
          Expires: expires_in.from_now.to_i,
          Access: "Full"
        }
      }
    )

    if response[:success] && response[:data][:ShareToken]
      return {
        success: true,
        token: response[:data][:ShareToken][:Token],
        url: response[:data][:ShareToken][:Url],
        expires_at: Time.at(response[:data][:ShareToken][:Expires])
      }
    else
      return { success: false, error: response[:error] || "Failed to create share token" }
    end
  end

  private

  def ensure_credentials_present
    missing = []
    missing << "SMUGMUG_OAUTH_TOKEN" if @oauth_token.blank?
    missing << "SMUGMUG_OAUTH_SECRET" if @oauth_secret.blank?
    missing << "SMUGMUG_API_KEY" if @api_key.blank?
    missing << "SMUGMUG_API_SECRET" if @api_secret.blank?
    missing << "SMUGMUG_USER" if @user.blank?

    if missing.any?
      error_message = "Missing Smugmug credentials: #{missing.join(', ')}"
      Rails.logger.warn(error_message)

      if Rails.env.production?
        raise error_message
      else
        # In development/test, just warn but continue
        Rails.logger.warn("Using mock mode in #{Rails.env} environment due to missing credentials")
      end
    end
  end

  def find_or_create_gallery(appointment)
    folder_path = folder_path_for_appointment(appointment)
    gallery_name = gallery_name_for_appointment(appointment)

    # First, try to find the gallery folder structure
    folder_response = make_api_request("folder/user/#{@user}#{folder_path}")

    # If folder doesn't exist, create the necessary folder structure
    unless folder_response[:success]
      # Create folder path recursively
      create_folder_path(folder_path)

      # Refresh folder response after creation
      folder_response = make_api_request("folder/user/#{@user}#{folder_path}")
      return { success: false, error: "Failed to create folder structure" } unless folder_response[:success]
    end

    # Now check if gallery already exists
    gallery_response = make_api_request("folder/user/#{@user}#{folder_path}!galleries")

    if gallery_response[:success] && gallery_response[:data][:Folder][:Galleries]
      existing_gallery = gallery_response[:data][:Folder][:Galleries].find { |g| g[:Name] == gallery_name }

      if existing_gallery
        return {
          uri: existing_gallery[:Uri],
          url: existing_gallery[:WebUri],
          key: existing_gallery[:NodeID]
        }
      end
    end

    # Create gallery if it doesn't exist
    create_response = make_api_request(
      "folder/user/#{@user}#{folder_path}!galleries",
      method: :post,
      data: {
        Gallery: {
          Name: gallery_name,
          Privacy: "Unlisted",
          SecurityType: "Password",
          Password: SecureRandom.hex(4).upcase,
          UrlName: "#{appointment.id}-#{Date.today.strftime('%Y%m%d')}"
        }
      }
    )

    if create_response[:success] && create_response[:data][:Gallery]
      return {
        uri: create_response[:data][:Gallery][:Uri],
        url: create_response[:data][:Gallery][:WebUri],
        key: create_response[:data][:Gallery][:NodeID]
      }
    else
      return { success: false, error: create_response[:error] || "Failed to create gallery" }
    end
  end

  def upload_image_to_gallery(gallery_uri, file)
    # First get the upload URI for the gallery
    response = make_api_request("#{gallery_uri}!uploaduri")
    return { success: false, error: response[:error] || "Failed to get upload URI" } unless response[:success]

    upload_uri = response[:data][:Uri]

    # Now perform the actual upload
    upload_response = make_api_request(
      upload_uri,
      method: :post,
      data: file.read,
      content_type: file.content_type,
      headers: {
        "X-Smug-FileName" => file.original_filename,
        "X-Smug-AlbumUri" => gallery_uri,
        "X-Smug-ResponseType" => "JSON"
      }
    )

    if upload_response[:success] && upload_response[:data][:Image]
      return {
        success: true,
        image_key: upload_response[:data][:Image][:ImageKey],
        image_url: upload_response[:data][:Image][:WebUri]
      }
    else
      return { success: false, error: upload_response[:error] || "Failed to upload image" }
    end
  end

  def make_api_request(endpoint, options = {})
    method = options[:method] || :get
    data = options[:data]
    content_type = options[:content_type] || "application/json"
    headers = options[:headers] || {}

    # Ensure endpoint has the API base URL if it's not a full URL
    unless endpoint.start_with?("http")
      endpoint = "#{API_BASE_URL}/#{endpoint.sub(/^\//, '')}"
    end

    # Set up OAuth
    consumer = OAuth::Consumer.new(@api_key, @api_secret, site: API_BASE_URL)
    access_token = OAuth::AccessToken.new(consumer, @oauth_token, @oauth_secret)

    # Add common headers
    headers["Accept"] = "application/json"
    headers["Content-Type"] = content_type unless method == :get

    begin
      response = case method
        when :get
          access_token.get(endpoint, headers)
        when :post
          if data.is_a?(Hash) || data.is_a?(Array)
            data = data.to_json unless content_type != "application/json"
          end
          access_token.post(endpoint, data, headers)
        when :put
          data = data.to_json if data.is_a?(Hash) || data.is_a?(Array)
          access_token.put(endpoint, data, headers)
        when :delete
          access_token.delete(endpoint, headers)
        else
          raise "Unsupported HTTP method: #{method}"
      end

      # Parse the response
      if response.code.to_i >= 200 && response.code.to_i < 300
        if response.body.present?
          parsed_response = JSON.parse(response.body, symbolize_names: true)
          return { success: true, data: parsed_response, response: response }
        else
          return { success: true, response: response }
        end
      else
        error_message = "API error: #{response.code}"
        begin
          error_data = JSON.parse(response.body, symbolize_names: true)
          error_message = error_data[:Message] if error_data[:Message]
        rescue JSON::ParserError
          error_message = response.body if response.body.present?
        end

        return { success: false, error: error_message, response: response }
      end
    rescue StandardError => e
      Rails.logger.error("API request failed: #{e.message}")
      return { success: false, error: e.message }
    end
  end

  def create_folder_path(path)
    path_parts = path.split('/').reject(&:empty?)
    current_path = ""

    path_parts.each do |part|
      current_path += "/#{part}"

      # Check if this part of the path exists
      folder_response = make_api_request("folder/user/#{@user}#{current_path}")

      # Create folder if it doesn't exist
      unless folder_response[:success]
        parent_path = current_path.split('/')[0...-1].join('/')
        folder_name = part

        make_api_request(
          "folder/user/#{@user}#{parent_path}!folders",
          method: :post,
          data: {
            Folder: {
              Name: folder_name,
              UrlName: folder_name.parameterize
            }
          }
        )
      end
    end
  end

  def folder_path_for_appointment(appointment)
    # Create a consistent folder structure: /YYYY/MM/Location/CustomerName-AppointmentID
    date = appointment.start_time.to_date
    location = appointment.location.parameterize
    customer_name = appointment.name.parameterize

    "/#{date.year}/#{date.month.to_s.rjust(2, '0')}/#{location}/#{customer_name}-#{appointment.id}"
  end

  def folder_path_for_customer(customer)
    # For retrieving a customer's galleries, we need to search by a pattern
    # This will be dependent on our naming convention defined above
    customer_name = customer.name.parameterize

    # This is a simplified approach - in practice you might need a more sophisticated search
    "/#{customer_name}"
  end

  def gallery_name_for_appointment(appointment)
    # Generate a consistent gallery name format
    date = appointment.start_time.to_date
    shoot_type = appointment.questions.find { |q| q.question == 'Type of shoots' }&.answer || "Photoshoot"

    "#{appointment.name} - #{shoot_type} - #{date.strftime('%Y-%m-%d')}"
  end

  # Mock implementations for development without API credentials

  def mock_upload_gallery(appointment, files)
    # Create a mock successful response
    gallery_key = "MOCK-#{SecureRandom.hex(8)}"
    gallery_url = "https://mocksmugmug.com/gallery/#{gallery_key}"

    results = {
      success: [],
      failed: []
    }

    files.each do |file|
      image_key = "IMG-#{SecureRandom.hex(6)}"
      results[:success] << { filename: file.original_filename, image_key: image_key }
    end

    return {
      success: true,
      gallery_url: gallery_url,
      gallery_key: gallery_key,
      results: results
    }
  end

  def mock_get_customer_galleries(customer)
    # Return a mock list of galleries
    galleries = [
      {
        title: "Mock Gallery 1",
        url: "https://mocksmugmug.com/gallery/mock1",
        key: "MOCK-1",
        date: Time.current.to_s,
        image_count: 10
      },
      {
        title: "Mock Gallery 2",
        url: "https://mocksmugmug.com/gallery/mock2",
        key: "MOCK-2",
        date: 1.day.ago.to_s,
        image_count: 15
      }
    ]

    return { success: true, galleries: galleries }
  end

  def mock_create_share_token(gallery_key, expires_in)
    # Create a mock share token
    token = "MOCKTOKEN-#{SecureRandom.hex(10)}"
    share_url = "https://mocksmugmug.com/share/#{token}"
    expires_at = expires_in.from_now

    return {
      success: true,
      token: token,
      url: share_url,
      expires_at: expires_at
    }
  end
end
