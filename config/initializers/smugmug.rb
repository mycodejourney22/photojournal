# config/initializers/smugmug.rb
Rails.application.config.after_initialize do
  # Check for required environment variables
  missing_vars = []
  %w[SMUGMUG_API_KEY SMUGMUG_API_SECRET SMUGMUG_OAUTH_TOKEN SMUGMUG_OAUTH_SECRET SMUGMUG_USER].each do |var|
    missing_vars << var if ENV[var].blank?
  end

  if missing_vars.any?
    warning = "WARNING: Missing Smugmug configuration variables: #{missing_vars.join(', ')}. "
    warning += "Smugmug integration will not work properly without these variables."

    # Log the warning
    Rails.logger.warn(warning)

    # Display warning in console during development
    puts "\e[33m#{warning}\e[0m" if Rails.env.development?
  end

  # Configure Sidekiq for the smugmug_uploads queue if Sidekiq is being used
  if defined?(Sidekiq)
    Sidekiq.configure_server do |config|
      config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
    end
  end
end

# Constants for Smugmug configuration
module SmugmugConfig
  # Gallery Defaults
  DEFAULT_PRIVACY = 'Unlisted'   # Options: Public, Unlisted, Private
  DEFAULT_SECURITY = 'Password'  # Options: None, Password, Url

  # Folder Structure (customize to match your desired organization)
  FOLDER_STRUCTURE = {
    root: '/',
    year_level: true,        # Use year-level folders, e.g. /2023/
    month_level: true,       # Use month-level folders, e.g. /2023/05/
    location_level: true,    # Use location-based folders, e.g. /2023/05/ikeja/
    customer_level: true     # Use customer-specific folders, e.g. /2023/05/ikeja/john-smith-12345/
  }

  # Upload settings
  MAX_CONCURRENT_UPLOADS = 5  # Maximum number of concurrent uploads to process
  RETRY_DELAY = 5.minutes     # Delay between retry attempts
  MAX_RETRIES = 3             # Maximum number of retry attempts

  # Share token expiration
  DEFAULT_SHARE_TOKEN_EXPIRY = 30.days  # Default expiration time for share tokens
end
