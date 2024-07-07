namespace :calendly do
  desc "Register the Calendly webhook"
  task register_webhook: :environment do
    require 'net/http'
    require 'uri'
    require 'json'

    url = 'https://api.calendly.com/webhook_subscriptions'
    uri = URI.parse(url)

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request['Authorization'] = "Bearer #{ENV['CALENDLY_BEARER_TOKEN']}"

    request.body = {
      url: 'https://photologger-0d07f7db019d.herokuapp.com/webhooks/calendly', # Replace with your actual endpoint
      events: ['invitee.created', 'invitee.canceled'], # Add any other events you want to subscribe to
      scope: 'organization',
      organization: ENV['CALENDLY_ORGANIZATION_UUID'] # Replace with your organization UUID
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"
  end
end
