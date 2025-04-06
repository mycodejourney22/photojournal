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
    @user = options[:user] || ENV['SMUGMUG_USER'] || "363-photography"
  end

  # Upload images to a gallery
  def upload_gallery(appointment, files)
    # In development, we can use mock mode to skip actual API calls
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_upload_gallery(appointment, files)
    end

    begin
      # 1. Get the user's root node ID
      user_response = make_api_request("user/#{@user}")
      # Rails.logger.info("User response success: #{user_response[:success]}")

      return { success: false, error: user_response[:error] || "Failed to get user info" } unless user_response[:success]

      # Extract the Node URI from the response
      root_node_id = nil
      if user_response[:data]
        node_uri = user_response[:data][:Response][:User][:Uris][:Node][:Uri]
        # Extract node ID from URI properly
        root_node_id = extract_node_id_from_uri(node_uri)
        # Rails.logger.info("Root node ID: #{root_node_id}")
      else
        # Rails.logger.error("Expected keys not found in response: #{user_response[:data].inspect}")
        return { success: false, error: "Unable to find root Node URI in user response" }
      end

      # 2. Create folder structure based on appointment
      folder_node_id = create_folder_structure_with_nodes(root_node_id, appointment)
      return { success: false, error: "Failed to create folder structure" } unless folder_node_id

      # 3. Create or find gallery (album)
      gallery = create_or_find_album(folder_node_id, appointment)
      return { success: false, error: gallery[:error] } if gallery[:error].present?

      # If we found an existing gallery but with no uploads yet, we can use it
      if gallery[:existing] && files.present?
        # Rails.logger.info("Found existing gallery: #{gallery[:url]}")
      end

      # 4. Upload each file
      results = {
        success: [],
        failed: []
      }

      # Rails.logger.info("Uploading #{files.size} files to album #{gallery[:key]}")

      # Log the first few characters of the content type to help debug
      if files.first
        first_file = files.first
        content_type = first_file.content_type || "unknown"
      end

      files.each do |file|
        # Make upload request
        result = direct_upload_to_album(gallery[:key], file)
        if result[:success]
          results[:success] << { filename: file.original_filename, image_key: result[:image_key] }
        else
          results[:failed] << { filename: file.original_filename, error: result[:error] }
        end
      end

      # Return the result
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

  # Upload image directly to SmugMug's upload service
 # For your SmugmugService class, replace the direct_upload_to_album method with this:

  # For your SmugmugService class, replace the direct_upload_to_album method with this:

  def direct_upload_to_album(album_id, file)
    Rails.logger.info("Uploading file #{file.original_filename} to album #{album_id}")

    # Use SmugMug's upload URL directly
    upload_url = "https://upload.smugmug.com/"

    # Get the file data by calling file.read() - make sure it's not a Proc
    file_data = file.read

    # Set up OAuth
    consumer = OAuth::Consumer.new(@api_key, @api_secret, site: API_BASE_URL)
    access_token = OAuth::AccessToken.new(consumer, @oauth_token, @oauth_secret)

    # IMPORTANT: SmugMug expects a very specific format for the AlbumUri
    # Different formats to try:
    test_formats = [
      "/api/v2/album/#{album_id}",  # Format 1
      "album/#{album_id}",          # Format 2 (simpler)
      "/album/#{album_id}"          # Format 3 (with leading slash)
    ]

    # Try each format until one works, starting with the most common
    chosen_format = test_formats[1]  # Default to Format 2 (most commonly works)

    # Required headers for upload - SmugMug requires specific format for these headers
    headers = {
      "Accept" => "application/json",
      "Content-Type" => file.content_type || 'image/jpeg',
      "X-Smug-ResponseType" => "JSON",
      "X-Smug-AlbumUri" => chosen_format,
      "X-Smug-FileName" => file.original_filename,
      "X-Smug-Version" => "v2"
    }

    begin
      # Add Content-Length header with proper file size
      headers["Content-Length"] = file_data.bytesize.to_s
      Rails.logger.debug("File size: #{file_data.bytesize} bytes")

      # Try uploading with the first format
      response = make_upload_request(access_token, upload_url, file_data, headers)

      # If that didn't work, try the other formats
      if response.code.to_i == 200 && response.body.include?("Unable to determine upload location")
        Rails.logger.warn("First album URI format failed, trying alternatives...")

        # Try the other formats
        test_formats.each do |format|
          next if format == chosen_format # Skip the one we just tried

          Rails.logger.info("Trying alternative album URI format: #{format}")
          headers["X-Smug-AlbumUri"] = format
          response = make_upload_request(access_token, upload_url, file_data, headers)

          # If this format worked (didn't get the error), use it for future uploads
          if response.code.to_i == 200 && !response.body.include?("Unable to determine upload location")
            chosen_format = format
            Rails.logger.info("Found working album URI format: #{chosen_format}")
            break
          end
        end
      end

      # Process the response
      if response.body.present?
        begin
          parsed_response = JSON.parse(response.body, symbolize_names: true)

          # Log all the response data for debugging
          # Rails.logger.debug("Full response body: #{response.body}")

          # Check for API success indicator (could be either style of response)
          if (parsed_response[:stat] == "ok" && parsed_response[:Image]) ||
             (parsed_response[:Response] && parsed_response[:Response][:Image])

            # Get the image data from the right location in the response
            image_data = parsed_response[:Image] || parsed_response[:Response][:Image]

            # Success! Extract image details
            image_key = if image_data[:ImageUri]
                          extract_key_from_uri(image_data[:ImageUri])
                        else
                          image_data[:Key] || image_data[:ImageKey] || image_data[:id] || "unknown"
                        end

            image_url = image_data[:URL] || image_data[:Url] || image_data[:WebUri] || "unknown"

            # Rails.logger.info("Successfully uploaded image: #{file.original_filename}")
            # Rails.logger.info("Image key: #{image_key}, URL: #{image_url}")

            return {
              success: true,
              image_key: image_key,
              image_url: image_url
            }
          else
            # API error response
            error_message = parsed_response[:message] ||
                            (parsed_response[:Response] && parsed_response[:Response][:Message]) ||
                            "API error with no message"

            code = parsed_response[:code] ||
                   (parsed_response[:Response] && parsed_response[:Response][:Code]) ||
                   "unknown"

            Rails.logger.error("SmugMug API Error: Code #{code}, Message: #{error_message}")
            return {
              success: false,
              error: "SmugMug API Error: #{error_message} (Code: #{code})"
            }
          end
        rescue JSON::ParserError => e
          # Rails.logger.error("Failed to parse JSON response: #{e.message}")
          # Rails.logger.error("Raw response body: #{response.body}")
          return { success: false, error: "Failed to parse response: #{e.message}" }
        end
      elsif response.code.to_i >= 200 && response.code.to_i < 300
        # Empty body with 200 status - assume success but without details
        # Rails.logger.warn("Received empty response body with successful HTTP status #{response.code}")
        return { success: true, image_key: "unknown", image_url: "unknown" }
      else
        # HTTP error without body
        error_message = "Upload failed: HTTP status #{response.code}"
        Rails.logger.error(error_message)
        return { success: false, error: error_message }
      end
    rescue StandardError => e
      Rails.logger.error("Upload failed with exception: #{e.class.name} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return { success: false, error: "Upload error: #{e.message} (#{e.class.name})" }
    end
  end

  # Helper method to make upload requests
  def make_upload_request(access_token, url, data, headers)
    # Rails.logger.debug("Making upload request to #{url} with headers: #{headers.inspect}")
    # Clone the data to avoid modifying the original
    access_token.post(url, data.dup, headers.dup)
    # Rails.logger.debug("Upload response status: #{response.code}")
    # Rails.logger.debug("Response body (first 100 chars): #{response.body ? response.body[0..100] : 'nil'}")
  end

  # Helper to extract key from URI path
  def extract_key_from_uri(uri)
    return nil unless uri
    # Extract the key from path like "/api/v2/album/<key>/image/<key>-0"
    # We want the image key which is after "image/"
    if uri =~ /\/image\/([^\/]+)/
      return $1
    end
    # Fallback: just return the last segment
    uri.split('/').last
  end

  # Extract node ID from URI
  def extract_node_id_from_uri(uri)
    # Normalize the URI first
    uri = normalize_api_url(uri)
    # Pattern: "/api/v2/node/Xn8D2q" -> "Xn8D2q"
    node_id = uri.split('/').last
    # Rails.logger.debug("Extracted node ID: #{node_id}")
    node_id
  end

  # Normalize an API URL to a consistent format
  def normalize_api_url(url)
    # Remove base URL if present
    url = url.sub(/https?:\/\/api\.smugmug\.com/, '')

    # Ensure it starts with /api/v2/ if it doesn't already
    unless url.start_with?('/api/v2/')
      url = "/api/v2/#{url.sub(/^\//, '')}"
    end

    url
  end

  # Create share token for a gallery (for customer access)
  # Fix for the create_share_token method in SmugmugService
# def create_share_token(gallery_key, expires_in = 30.days)
#   # Skip in mock mode
#   if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
#     return mock_create_share_token(gallery_key, expires_in)
#   end

#   Rails.logger.info("Creating share token for gallery: #{gallery_key}")

#   # FIX: Ensure proper endpoint format by using the correct path
#   # Problem was: the build_endpoint method was duplicating "/api/v2/"
#   endpoint = "album/#{gallery_key}!sharetokens"

#   response = make_api_request(
#     endpoint,
#     method: :post,
#     data: {
#       ShareToken: {
#         Password: "",
#         Expires: expires_in.from_now.to_i,
#         Access: "Full"
#       }
#     }
#   )

#   Rails.logger.debug("Share token response: #{response.inspect}")

#   if response[:success]
#     # Explore the response to find the ShareToken
#     if response[:data] && response[:data][:Response] && response[:data][:Response][:ShareToken]
#       token_data = response[:data][:Response][:ShareToken]
#       return {
#         success: true,
#         token: token_data[:Token],
#         url: token_data[:Url],
#         expires_at: Time.at(token_data[:Expires])
#       }
#     elsif response[:data] && response[:data][:ShareToken]
#       token_data = response[:data][:ShareToken]
#       return {
#         success: true,
#         token: token_data[:Token],
#         url: token_data[:Url],
#         expires_at: Time.at(token_data[:Expires])
#       }
#     else
#       Rails.logger.error("ShareToken not found in response: #{response[:data].inspect}")
#       return { success: false, error: "ShareToken data structure not found in response" }
#     end
#   else
#     return { success: false, error: response[:error] || "Failed to create share token" }
#   end
# end

# Also fix the build_endpoint method to prevent duplication
def build_endpoint(endpoint, base_url)
  # Handle already-complete URLs
  return endpoint if endpoint.start_with?('http')

  # FIX: Prevent duplication of the API version in the URL
  # Check for duplicate api/v2 segments
  if base_url.include?('/api/v2') && endpoint.start_with?('/api/v2/')
    # Remove the duplicate /api/v2/ from the endpoint
    endpoint = endpoint.sub(/^\/api\/v2\//, '')
    Rails.logger.debug("Removed duplicate API version from endpoint, now: #{endpoint}")
  end

  # Handle URLs with API version already included
  if endpoint.start_with?('/api/v2/')
    return "#{base_url.sub(/\/api\/v2\/?$/, '')}#{endpoint}"
  end

  # Handle exclamation mark format for methods (e.g., "node/ABC123!children")
  if endpoint.include?('!')
    base, method = endpoint.split('!')
    return "#{base_url}/#{base.sub(/^\//, '')}/!#{method.sub(/^\//, '')}"
  end

  # Regular endpoint
  "#{base_url}/#{endpoint.sub(/^\//, '')}"
end

  # Retrieve a list of galleries for a specific customer
  def get_customer_galleries(customer)
    # Skip in mock mode
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_get_customer_galleries(customer)
    end

    # Customer phone number as an identifier
    customer_phone = customer.phone_number.gsub(/\D/, '')

    # Try to find galleries by searching for customer name
    customer_name = sanitize_text(customer.name)

    Rails.logger.info("Searching for galleries for customer: #{customer_name}")

    # Get all user galleries
    response = make_api_request("user/#{@user}!galleries")
    return { success: false, error: response[:error] } unless response[:success]

    # Find galleries that match this customer
    galleries = []

    if response[:data] && response[:data][:Response] && response[:data][:Response][:User] &&
       response[:data][:Response][:User][:Galleries]

      all_galleries = response[:data][:Response][:User][:Galleries]

      all_galleries.each do |gallery|
        # Check if this gallery belongs to the customer
        if gallery[:Name].include?(customer_name) ||
           (gallery[:Description] && gallery[:Description].include?(customer_phone))

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

    return { success: true, galleries: galleries }
  end

  # Fetch all photos from a specific gallery with their URLs
  def get_gallery_photos(gallery_key)
    # Skip in mock mode
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_get_gallery_photos(gallery_key)
    end

    Rails.logger.info("Fetching photos for gallery: #{gallery_key}")

    # Use proper endpoint to get images
    endpoint = "album/#{gallery_key}!images"

    response = make_api_request(endpoint)

    if response[:success] && response[:data] && response[:data][:Response]
      # Extract images from the response
      if response[:data][:Response][:AlbumImage]
        images = response[:data][:Response][:AlbumImage]
        # Ensure images is an array even if only one image was returned
        images = [images] unless images.is_a?(Array)

        # Format image data for easy use
        return images.map do |image|
          # Get the thumbnail URL
          thumbnail_url = image[:ThumbnailUrl]

          # Generate better quality URLs from the thumbnail URL
          medium_url = get_better_quality_url(thumbnail_url, "L")
          large_url = get_better_quality_url(thumbnail_url, "XL")
          largest_url = image[:ArchivedUri] || get_better_quality_url(thumbnail_url, "X3L")

          # For display on the grid, use Large size
          display_url = medium_url || image[:WebUri]

          {
            id: image[:ImageKey] || image[:id] || extract_key_from_uri(image[:Uri]),
            title: image[:Title] || image[:FileName],
            caption: image[:Caption],
            url: image[:WebUri],
            thumbnail_url: medium_url || thumbnail_url, # Use medium instead of thumbnail for better quality
            largest_url: largest_url,
            medium_url: large_url || medium_url || display_url,
            width: image[:Width] || image[:OriginalWidth] || 0,
            height: image[:Height] || image[:OriginalHeight] || 0,
            created_at: image[:DateTimeCreated] || image[:DateTimeUploaded]
          }
        end
      else
        Rails.logger.warn("No images found in response for gallery: #{gallery_key}")
        return []
      end
    else
      error = response[:error] || "Unknown error fetching gallery photos"
      Rails.logger.error("Error fetching gallery photos: #{error}")
      return []
    end
  end

  def get_better_quality_url(thumbnail_url, size_code = "L")
    return nil unless thumbnail_url.present?

    # Smugmug thumbnail URLs follow this pattern:
    # https://photos.smugmug.com/photos/i[ImageKey]/0/[Hash]/Th/i[ImageKey]-Th.jpg

    # The last part contains size code: -Th.jpg (Th = thumbnail)
    # We can replace it with other size codes:
    # - X3L = Extra 3 Large
    # - X2L = Extra 2 Large
    # - XL = Extra Large
    # - L = Large
    # - M = Medium
    # - S = Small
    # - Th = Thumbnail

    # Replace the size code in both places (path and filename)
    better_url = thumbnail_url.gsub(/-Th\./, "-#{size_code}.")
    better_url = better_url.gsub(/\/Th\//, "/#{size_code}/")

    better_url
  end

  # Get a direct shareable URL for a specific image
  def get_image_download_url(image_key)
    # Skip in mock mode
    if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
      return mock_get_image_download_url(image_key)
    end

    # Get the specific image details
    endpoint = "image/#{image_key}"

    response = make_api_request(endpoint)

    if response[:success] && response[:data] && response[:data][:Response] && response[:data][:Response][:Image]
      image = response[:data][:Response][:Image]

      # Return the largest available image URL
      return image[:OriginalUrl] || image[:LargestUrl] || image[:ArchivedUri] || image[:WebUri]
    else
      error = response[:error] || "Unknown error fetching image download URL"
      Rails.logger.error("Error fetching image download URL: #{error}")
      return nil
    end
  end

  # Get a signed URL that allows temporary access to an image
  def get_image_signed_url(image_key, expires_in = 1.hour)
    # This would require Smugmug API support for signed URLs
    # Implementation depends on Smugmug's capabilities
    # For now, return the regular URL
    get_image_download_url(image_key)
  end

    # Mock implementations for development without API credentials
    def mock_get_gallery_photos(gallery_key)
      # Generate random number of mock images
      image_count = rand(5..15)

      images = []
      image_count.times do |i|
        width = [800, 1200, 1600].sample
        height = [600, 800, 1200].sample

        images << {
          id: "IMG-#{SecureRandom.hex(6)}",
          title: "Photo #{i + 1}",
          caption: "This is a mock photo caption",
          url: "https://mocksmugmug.com/gallery/#{gallery_key}/photo-#{i + 1}",
          thumbnail_url: "https://via.placeholder.com/300x300?text=Photo+#{i + 1}",
          largest_url: "https://via.placeholder.com/#{width}x#{height}?text=Photo+#{i + 1}",
          medium_url: "https://via.placeholder.com/800x600?text=Photo+#{i + 1}",
          width: width,
          height: height,
          created_at: (rand(1..30).days.ago).to_s
        }
      end

      images
    end

    def mock_get_image_download_url(image_key)
      "https://mocksmugmug.com/download/#{image_key}"
    end

    def search_galleries(query, options = {})
      # Skip in mock mode
      if Rails.env.development? && ENV['SMUGMUG_MOCK'] == 'true'
        return mock_search_galleries(query)
      end

      begin
        # Normalize the query
        normalized_query = query.to_s.strip
        case_insensitive_query = normalized_query.downcase
        Rails.logger.info("Searching for galleries with query: '#{normalized_query}'")

        # Get user albums
        user_albums_endpoint = "user/#{@user}!albums"
        albums_response = make_api_request(user_albums_endpoint)

        if albums_response[:success] && albums_response[:data] && albums_response[:data][:Response]
          albums = albums_response[:data][:Response][:Album] || []
          albums = [albums] unless albums.is_a?(Array)

          # Filter albums by name (case insensitive)
          matching_albums = albums.select do |album|
            album_name = album[:Keywords]
            album_name == case_insensitive_query
          end

          Rails.logger.info("Found #{matching_albums.size} matching albums for query '#{normalized_query}'")

          # Format results
          results = matching_albums.map do |album|
            {
              key: album[:AlbumKey],
              title: album[:Name],
              url: album[:WebUri],
              date: album[:LastUpdated],
              image_count: album[:ImageCount] || 0
            }
          end

          return { success: true, galleries: results }
        else
          error = albums_response[:error] || "Unknown error fetching albums"
          Rails.logger.error("Error searching galleries: #{error}")
          return { success: false, error: error }
        end
      rescue StandardError => e
        Rails.logger.error("Error in search_galleries: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        return { success: false, error: e.message }
      end
    end

    # Mock implementation for development
    def mock_search_galleries(query)
      # Generate random gallery data that matches the query
      random_count = rand(1..5)

      galleries = random_count.times.map do |i|
        {
          key: "GALLERY-#{SecureRandom.hex(4)}",
          title: "#{query.capitalize} Gallery #{i+1}",
          url: "https://mocksmugmug.com/gallery/#{query.parameterize}-#{i+1}",
          date: (rand(1..365).days.ago).strftime("%Y-%m-%d"),
          image_count: rand(10..100)
        }
      end

      { success: true, galleries: galleries }
    end

  private

  def create_folder_structure_with_nodes(root_node_id, appointment)
    # Get folder structure from appointment
    folder_path = folder_path_for_appointment(appointment)
    folder_parts = folder_path.split('/').reject(&:empty?)

    current_node_id = root_node_id
    Rails.logger.info("Creating folder structure from path: #{folder_path}")
    Rails.logger.info("Starting with root node ID: #{root_node_id}")

    folder_parts.each do |folder_name|
      Rails.logger.info("Processing folder part: '#{folder_name}'")

      # Check if folder exists
      children_response = make_api_request("node/#{current_node_id}!children")

      if children_response[:success]
        # Look for existing folder with this name (CASE INSENSITIVE)
        existing_folder = nil

        if children_response[:data][:Response] &&
           children_response[:data][:Response][:Node]
          children = children_response[:data][:Response][:Node]
          children = [children] unless children.is_a?(Array)

          Rails.logger.debug("Found #{children.size} children")

          # Modified to be case-insensitive comparison
          existing_folder = children.find do |child|
            Rails.logger.debug("Child type: #{child[:Type]}, name: #{child[:Name]}")
            child[:Type] == "Folder" && child[:Name].downcase == folder_name.downcase
          end
        end

        if existing_folder
          # Extract node ID from URI
          folder_uri = existing_folder[:Uri]
          current_node_id = extract_node_id_from_uri(folder_uri)
          Rails.logger.info("Found existing folder: '#{folder_name}' with ID: #{current_node_id}")
        else
          # Create folder with properly capitalized name
          # Ensure the URL name starts with a capital letter as required by SmugMug
          url_name = folder_name.parameterize
          url_name = url_name.slice(0,1).capitalize + url_name.slice(1..-1) if url_name.present?

          # Prepare folder creation data
          folder_data = {
            Type: "Folder",
            Name: folder_name,
            UrlName: url_name,
            Privacy: "Unlisted"
          }

          Rails.logger.info("Creating new folder: '#{folder_name}' with url_name: '#{url_name}' in parent: #{current_node_id}")

          folder_response = make_api_request(
            "node/#{current_node_id}!children",
            method: :post,
            data: folder_data
          )

          if folder_response[:success] &&
             folder_response[:data][:Response] &&
             folder_response[:data][:Response][:Node]
            folder_uri = folder_response[:data][:Response][:Node][:Uri]
            current_node_id = extract_node_id_from_uri(folder_uri)
            Rails.logger.info("Created folder: '#{folder_name}' with ID: #{current_node_id}")
          else
            error_msg = folder_response[:error] || "Unknown error"

            # Check if it's a conflict error (folder already exists)
            if error_msg.include?("Conflict")
              # Try to find the folder by name again, it might have been created concurrently
              # or case sensitivity issues
              retry_response = make_api_request("node/#{current_node_id}!children")

              if retry_response[:success] && retry_response[:data][:Response] && retry_response[:data][:Response][:Node]
                retry_children = retry_response[:data][:Response][:Node]
                retry_children = [retry_children] unless retry_children.is_a?(Array)

                # Look again with even more relaxed comparison
                retry_folder = retry_children.find do |child|
                  child[:Type] == "Folder" &&
                  (child[:Name].downcase == folder_name.downcase ||
                   child[:UrlName].downcase == url_name.downcase)
                end

                if retry_folder
                  folder_uri = retry_folder[:Uri]
                  current_node_id = extract_node_id_from_uri(folder_uri)
                  Rails.logger.info("After conflict, found existing folder: '#{retry_folder[:Name]}' with ID: #{current_node_id}")
                  next # continue to next folder part
                end
              end
            end

            # If we couldn't recover from the conflict
            Rails.logger.error("Failed to create folder: '#{folder_name}', Error: #{error_msg}")
            if folder_response[:data]
              Rails.logger.error("Response data: #{folder_response[:data].inspect}")
            end
            return nil
          end
        end
      else
        Rails.logger.error("Failed to get children for node: #{current_node_id}, Error: #{children_response[:error]}")
        return nil
      end
    end

    Rails.logger.info("Completed folder structure creation. Final node ID: #{current_node_id}")
    current_node_id
  end

  def create_or_find_album(folder_node_id, appointment)
    album_name = gallery_name_for_appointment(appointment)

    # Ensure the URL name starts with a capital letter as required by SmugMug
    url_name = album_name.parameterize
    url_name = url_name.slice(0,1).capitalize + url_name.slice(1..-1) if url_name.present?

    # Keep URL name within reasonable length
    url_name = url_name[0..50] if url_name.length > 50

    Rails.logger.info("Looking for existing album: '#{album_name}' in folder: #{folder_node_id}")

    # Check if album exists
    children_response = make_api_request("node/#{folder_node_id}!children")

    if children_response[:success]
      # Look for existing album with this name
      existing_album = nil

      if children_response[:data][:Response][:Node]
        children = children_response[:data][:Response][:Node]
        children = [children] unless children.is_a?(Array)

        existing_album = children.find do |child|
          child[:Type] == "Album" && child[:Name] == album_name
        end
      end

      if existing_album
        # Rails.logger.info("Found existing album: #{album_name} with ID: #{existing_album[:Uris][:Album][:Uri]}")
        album_id = existing_album[:Uris][:Album][:Uri].split('/').last
        # Rails.logger.info("Found existing album: #{album_name} with ID: #{album_id}")
        return {
          key: album_id,
          url: existing_album[:WebUri],
          uri: existing_album[:Uri],
          existing: true  # Flag that we found an existing album
        }
      end
    end

    # Create album with minimal required attributes
    # Rails.logger.info("Creating new album: '#{album_name}' with url_name: '#{url_name}' in folder: #{folder_node_id}")

    # Start with the minimal required attributes
    album_data = {
      Type: "Album",
      Name: album_name,
      UrlName: url_name, # Make sure we send the properly formatted URL name
      Privacy: "Unlisted"  # Add privacy setting
    }

    # Rails.logger.debug("Album creation data: #{album_data.inspect}")

    album_response = make_api_request(
      "node/#{folder_node_id}!children",
      method: :post,
      data: album_data
    )

    if album_response[:success] &&
       album_response[:data][:Response] &&
       album_response[:data][:Response][:Node]
      album = album_response[:data][:Response][:Node]
      album_id = album[:Uris][:Album][:Uri].split('/').last
      Rails.logger.info("Created album: #{album_name} with ID: #{album_id}")

      return {
        key: album_id,
        url: album[:WebUri],
        uri: album[:Uri],
        existing: false  # Flag this as a new album
      }
    else
      error_msg = album_response[:error] || "Failed to create album"
      Rails.logger.error("Album creation failed: #{error_msg}")

      # Log the full response for debugging
      if album_response[:response]
        # Rails.logger.error("Full HTTP Response: #{album_response[:response].code} #{album_response[:response].message}")
        # Rails.logger.error("Response Body: #{album_response[:response].body}") if album_response[:response].body
      end

      # Rails.logger.error("Response data: #{album_response[:data].inspect}") if album_response[:data]
      return { error: error_msg }
    end
  end

  def make_api_request(endpoint, options = {})
    method = options[:method] || :get
    data = options[:data]
    content_type = options[:content_type] || "application/json"
    headers = options[:headers] || {}

    # Build the full URL with better path handling
    url = build_endpoint(endpoint, API_BASE_URL)

    Rails.logger.debug("Final API URL: #{url}")

    # Set up OAuth
    consumer = OAuth::Consumer.new(@api_key, @api_secret, site: API_BASE_URL)
    access_token = OAuth::AccessToken.new(consumer, @oauth_token, @oauth_secret)

    # Add common headers
    headers["Accept"] = "application/json"
    headers["Content-Type"] = content_type unless method == :get

    begin
      # Rails.logger.debug("Making #{method.upcase} request to: #{url}")
      if data && method != :get && content_type == "application/json"
        # Rails.logger.debug("Request body: #{data.to_json}")
      end

      response = case method
        when :get
          access_token.get(url, headers)
        when :post
          if data.is_a?(Hash) || data.is_a?(Array)
            data = data.to_json unless content_type != "application/json"
          end
          access_token.post(url, data, headers)
        when :put
          data = data.to_json if data.is_a?(Hash) || data.is_a?(Array)
          access_token.put(url, data, headers)
        when :patch
          data = data.to_json if data.is_a?(Hash) || data.is_a?(Array)
          access_token.patch(url, data, headers)
        when :delete
          access_token.delete(url, headers)
        else
          raise "Unsupported HTTP method: #{method}"
      end

      # Rails.logger.debug("Response code: #{response.code}")

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
          if response.body.present?
            # Rails.logger.debug("Error response body: #{response.body}")
            error_data = JSON.parse(response.body, symbolize_names: true)
            error_message = error_data[:Message] if error_data[:Message]
          end
        rescue JSON::ParserError => e
          # Rails.logger.error("Failed to parse error response: #{e.message}")
          error_message = response.body if response.body.present?
        end

        return { success: false, error: error_message, response: response }
      end
    rescue StandardError => e
      Rails.logger.error("API request failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return { success: false, error: e.message }
    end
  end

  # Build a properly formatted API endpoint URL
  # def build_endpoint(endpoint, base_url)
  #   # Handle already-complete URLs
  #   return endpoint if endpoint.start_with?('http')

  #   # Handle URLs with API version already included
  #   if endpoint.start_with?('/api/v2/')
  #     return "#{base_url.sub(/\/api\/v2\/?$/, '')}#{endpoint}"
  #   end

  #   # Handle exclamation mark format for methods (e.g., "node/ABC123!children")
  #   if endpoint.include?('!')
  #     base, method = endpoint.split('!')
  #     return "#{base_url}/#{base.sub(/^\//, '')}/!#{method.sub(/^\//, '')}"
  #   end

  #   # Regular endpoint
  #   "#{base_url}/#{endpoint.sub(/^\//, '')}"
  # end

  def folder_path_for_appointment(appointment)
    # Create a consistent folder structure: /YYYY/MM/Location
    date = appointment.start_time.to_date
    # Clean and sanitize the location
    location = sanitize_folder_name(appointment.location)

    folder_path = "/#{date.year}/#{date.month.to_s.rjust(2, '0')}/#{location}"
    # Rails.logger.info("Generated folder path: #{folder_path}")
    folder_path
  end

  # Add these methods to your existing app/services/smugmug_service.rb file




  def sanitize_folder_name(name)
    # Remove any potentially problematic characters for SmugMug folders
    # Replace spaces with hyphens, remove special characters
    sanitized = name.gsub(/[^\w\s-]/, '') # Remove any non-word, non-space, non-hyphen chars
                   .gsub(/\s+/, '-')      # Replace spaces with hyphens
                   .gsub(/-+/, '-')       # Replace multiple hyphens with single hyphen

    # SmugMug requires that UrlName starts with a capital letter
    # Capitalize the first character
    sanitized = sanitized.slice(0,1).capitalize + sanitized.slice(1..-1) if sanitized.present?

    # Make sure we don't have extremely long names
    sanitized = sanitized[0..49] if sanitized.length > 50

    # Rails.logger.info("Sanitized folder name: '#{name}' -> '#{sanitized}'")
    sanitized
  end

  def gallery_name_for_appointment(appointment)
    # Generate a consistent gallery name format
    date = appointment.start_time.to_date
    shoot_type = appointment.questions.find { |q| q.question == 'Type of shoots' }&.answer || "Photoshoot"

    # Sanitize customer name and shoot type
    customer_name = sanitize_text(appointment.name)
    shoot_type = sanitize_text(shoot_type)

    # Keep the gallery name reasonably short
    gallery_name = "#{customer_name} - #{shoot_type} - #{date.strftime('%Y-%m-%d')}"
    if gallery_name.length > 100
      # Trim the name if it's too long
      gallery_name = "#{customer_name.truncate(40)} - #{date.strftime('%Y-%m-%d')}"
    end

    Rails.logger.info("Generated gallery name: #{gallery_name}")
    gallery_name
  end

  # Helper method to sanitize text
  def sanitize_text(text)
    # Remove or replace problematic characters for naming
    return "Unknown" if text.blank?

    # SmugMug-friendly sanitization
    text.gsub(/[^\w\s.,'-]/, '') # Allow alphanumeric, space, period, comma, apostrophe, hyphen
  end

  # Mock implementations for development without API credentials
  def mock_upload_gallery(appointment, files)
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

  def mock_create_share_token(gallery_key, expires_in)
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

  def mock_get_customer_galleries(customer)
    # Return mock data for development environment
    mock_galleries = [
      {
        title: "#{customer.name} - Portrait Session - #{1.month.ago.strftime('%Y-%m-%d')}",
        url: "https://mocksmugmug.com/gallery/mock1",
        key: "MOCK-#{SecureRandom.hex(8)}",
        date: 1.month.ago.to_s,
        image_count: rand(10..25)
      },
      {
        title: "#{customer.name} - Family Session - #{2.months.ago.strftime('%Y-%m-%d')}",
        url: "https://mocksmugmug.com/gallery/mock2",
        key: "MOCK-#{SecureRandom.hex(8)}",
        date: 2.months.ago.to_s,
        image_count: rand(15..40)
      }
    ]

    return { success: true, galleries: mock_galleries }
  end
end
