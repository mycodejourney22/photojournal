require 'oauth'
require 'webrick'
require 'launchy'

# Enter your API credentials here
API_KEY = 'c9mw2GKMVscxt3m7XXd78q5xbFMZg33G'
API_SECRET = 'jpcmSwhSspgVQHk4sjnx83D3rXXtPFkhJqcg9JFk27fkwkJwtmtdGbgntHfKBD5K'
CALLBACK_PORT = 3000
CALLBACK_URL = "http://localhost:#{CALLBACK_PORT}/oauth_callback"

puts "Starting OAuth token generation process..."
puts "Using API Key: #{API_KEY}"

# Create OAuth consumer
consumer = OAuth::Consumer.new(
  API_KEY,
  API_SECRET,
  {
    site: "https://api.smugmug.com",
    request_token_path: "/services/oauth/1.0a/getRequestToken",
    authorize_path: "/services/oauth/1.0a/authorize",
    access_token_path: "/services/oauth/1.0a/getAccessToken"
  }
)

begin
  # Step 1: Get request token
  request_token = consumer.get_request_token(oauth_callback: CALLBACK_URL)
  puts "Request token obtained: #{request_token.token}"

  # Step 2: Generate authorization URL
  authorize_url = request_token.authorize_url
  puts "\nPlease authorize the application by visiting this URL in your browser:"
  puts authorize_url

  # Open the URL in the default browser
  Launchy.open(authorize_url)

  # Step 3: Create a simple web server to receive the callback
  puts "\nWaiting for authorization callback..."
  server = WEBrick::HTTPServer.new(Port: CALLBACK_PORT)

  oauth_verifier = nil
  server.mount_proc '/oauth_callback' do |req, res|
    oauth_verifier = req.query['oauth_verifier']
    res.body = "<html><body><h2>Authorization Successful!</h2><p>You can close this window and return to the terminal.</p></body></html>"
    server.shutdown
  end

  # Trap signals to ensure server shutdown
  trap('INT') { server.shutdown }
  trap('TERM') { server.shutdown }

  # Start the server and wait for callback
  server.start

  # Step 4: Exchange request token for access token
  if oauth_verifier
    puts "Received OAuth verifier: #{oauth_verifier}"
    puts "Exchanging for access token..."

    access_token = request_token.get_access_token(oauth_verifier: oauth_verifier)

    puts "\n----- SUCCESS! YOUR SMUGMUG OAUTH CREDENTIALS -----"
    puts "SMUGMUG_OAUTH_TOKEN=#{access_token.token}"
    puts "SMUGMUG_OAUTH_SECRET=#{access_token.secret}"
    puts "------------------------------------------------------"
    puts "\nAdd these to your environment variables to use with your application."
  else
    puts "Failed to receive OAuth verifier."
  end

rescue => e
  puts "Error during OAuth process: #{e.message}"
  puts e.backtrace.join("\n")
end
