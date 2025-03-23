# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # Custom error class for Smugmug API errors
  class SmugmugApiError < StandardError; end

  # Retry with exponential backoff for API errors
  retry_on SmugmugApiError, wait: :exponentially_longer, attempts: 5

  # Set up queue priority
  queue_as :default

  # Override queue_as to allow for dynamic queue selection
  class << self
    def queue_with(queue_name)
      queue_as queue_name
    end
  end
end
