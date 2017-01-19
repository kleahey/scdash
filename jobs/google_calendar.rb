require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'
require 'json'
require 'sinatra'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'
CLIENT_SECRETS_PATH = 'assets/client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "calendar-ruby-quickstart.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
enable :sessions
set :session_secret, 'setme'

get '/' do
  unless session.has_key?(:credentials)
    redirect to('/oauth2callback')
  end
  client_opts = JSON.parse(session[:credentials])
  auth_client = Signet::OAuth2::Client.new(client_opts)
  drive = Google::Apis::CalendarV3::DriveService.new
  files = drive.list_files(options: { authorization: auth_client })
  "<pre>#{JSON.pretty_generate(files.to_h)}</pre>"
end

get '/oauth2callback' do
  client_secrets = Google::APIClient::ClientSecrets.load
  auth_client = client_secrets.to_authorization
  auth_client.update!(
    :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
    :redirect_uri => url('/oauth2callback'))
  if request['code'] == nil
    auth_uri = auth_client.authorization_uri.to_s
    redirect to(auth_uri)
  else
    auth_client.code = request['code']
    auth_client.fetch_access_token!
    auth_client.client_secret = nil
    session[:credentials] = auth_client.to_json
    redirect to('https://vast-shore-30956.herokuapp.com/today')
  end
end

SCHEDULER.every '15m', :first_in => 0 do |job|

  # Initialize the API
  service = Google::Apis::CalendarV3::CalendarService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize

  # Fetch the next 10 events from the calendar
  calendar_id = 'commonapp.org_ipqcbb48uos49b390bk1bnkj04@group.calendar.google.com'
  response = service.list_events(calendar_id,
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)

  calendarEntries = response.items.map do |row|
    if row.start.date <= Time.now.strftime('%Y-%m-%d') then
      row = {
        :label => row.summary
      }
    end
  end

  send_event('calendar', { items: calendarEntries })

end
