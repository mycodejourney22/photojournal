require 'sidekiq'

redis_url = ENV['REDIS_URL']

Sidekiq.configure_server do |config|
  if redis_url.start_with?('rediss://')
    # For SSL connections to Redis, disable certificate verification
    config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    }
  else
    config.redis = { url: redis_url }
  end
end

Sidekiq.configure_client do |config|
  if redis_url.start_with?('rediss://')
    # For SSL connections to Redis, disable certificate verification
    config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    }
  else
    config.redis = { url: redis_url }
  end
end
