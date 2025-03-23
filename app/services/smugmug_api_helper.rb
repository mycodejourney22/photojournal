# app/services/smugmug_api_helper.rb
module SmugmugApiHelper
  # Class methods that can be called directly
  class << self
    # Build a properly formatted API endpoint URL
    def build_endpoint(endpoint, base_url)
      # Handle already-complete URLs
      return endpoint if endpoint.start_with?('http')

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

    # Extract node ID from URI
    def extract_node_id_from_uri(uri)
      # Normalize the URI first
      uri = normalize_api_url(uri)
      # Pattern: "/api/v2/node/Xn8D2q" -> "Xn8D2q"
      node_id = uri.split('/').last
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

    # Sanitize text for use in names and paths
    def sanitize_text(text)
      # Remove or replace problematic characters for naming
      return "Unknown" if text.blank?

      # SmugMug-friendly sanitization
      text.gsub(/[^\w\s.,'-]/, '') # Allow alphanumeric, space, period, comma, apostrophe, hyphen
    end

    # Sanitize folder name for SmugMug
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

      sanitized
    end

    # Extract key from URI path
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
  end
end
