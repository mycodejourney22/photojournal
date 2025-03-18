
# Check if the required environment variables are present
required_vars = %w[EBULK_SMS_USERNAME EBULK_SMS_API_KEY]

missing_vars = required_vars.select { |var| ENV[var].blank? }
if missing_vars.any?
  Rails.logger.warn "WARNING: Missing EbulkSMS configuration variables: #{missing_vars.join(', ')}"
  Rails.logger.warn "SMS functionality will not work without these variables."
end

# Set a default sender name if not provided
ENV['EBULK_SMS_SENDER_NAME'] ||= '363Photos'
