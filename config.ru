require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
      # Define allowed ips
      @ips = ['207.243.114.66', '127.0.0.1']

      # If request ip not included
      if not @ips.include? request.ip
        # Deny request
        throw(:halt, [401, "Not authorized\n"])
      end
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
