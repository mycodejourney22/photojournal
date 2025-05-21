# require 'sidekiq'
# require 'sidekiq-scheduler'


# redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'

# Sidekiq.configure_server do |config|
#   if redis_url.start_with?('rediss://')
#     # For SSL connections to Redis, disable certificate verification
#     config.redis = {
#       url: redis_url,
#       ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
#     }
#   else
#     config.redis = { url: redis_url }
#   end

#   Sidekiq.schedule = YAML.load_file(File.join(Rails.root, 'config/sidekiq.yml'))
#   Sidekiq::Scheduler.reload_schedule!
# end

# Sidekiq.configure_client do |config|
#   if redis_url.start_with?('rediss://')
#     # For SSL connections to Redis, disable certificate verification
#     config.redis = {
#       url: redis_url,
#       ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
#     }
#   else
#     config.redis = { url: redis_url }
#   end
# end

require 'sidekiq'
require 'sidekiq-scheduler'
require 'yaml'

redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'

# Load schedule from YAML file and convert to compatible format
schedule_file = File.join(Rails.root, 'config/sidekiq_schedule.yml')
if File.exist?(schedule_file)
  schedule = YAML.load_file(schedule_file)
else
  schedule = {}
end

Sidekiq.configure_server do |config|
  # Set up Redis connection with SSL handling
  if redis_url.start_with?('rediss://')
    # For SSL connections to Redis, disable certificate verification
    config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    }
  else
    config.redis = { url: redis_url }
  end
  
  # Set up scheduler
  Sidekiq::Scheduler.enabled = true
  Sidekiq::Scheduler.dynamic = true
  
  # Manually set up schedule
  Sidekiq.set_schedule('check_missed_appointments', {
    'cron' => '0 9 * * *',
    'class' => 'CheckMissedAppointmentsJob',
    'queue' => 'default',
    'description' => 'Check for appointments that were missed yesterday'
  })
  
  Sidekiq.set_schedule('check_expired_appointments', {
    'cron' => '0 * * * *',
    'class' => 'CheckExpiredAppointmentsJob',
    'queue' => 'default',
    'description' => 'Check for unpaid appointments that are about to expire'
  })
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
