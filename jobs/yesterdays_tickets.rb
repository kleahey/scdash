require 'rubygems'
require 'net/http'
require 'net/https'
require 'xmlsimple'
require 'pp'
require 'time'
require 'date'

configuration =
{
  :hostname   => 'd19.parature.com',
  :account_id => '33011',
  :token      => 'Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=',
  :applicant_id => '33013', # ID for a specific example customer you want to use
  :recommender_id => '33014'  # ID for a specific example CSR you want to use
}

SCHEDULER.every '15s', :first_in => 0 do |job|

# Connect to Parature's API for Applicant accounts
def applicant_requests(configuration, request_params, request_method, request_body = nil)

  # Build the host name and port portion of the URL that will be used by all future requests.
  base_url = URI.parse("https://#{configuration[:hostname]}/")

  # Create a request object and configure it to use HTTPS.
  request = Net::HTTP.new(base_url.host, base_url.port)
  request.use_ssl = true
  request.verify_mode = OpenSSL::SSL::VERIFY_NONE

  # Assemble the request URL from the connection parameters (fixed for each request)
  # request specific parameters and then append the authentication token.
  request_url = "/api/v1/#{configuration[:account_id]}/#{configuration[:applicant_id]}/#{request_params}&_token_=#{configuration[:token]}"

  # If the call provided a request body then convert it from the XmlSimple format of nested hashes
  # and lists to raw xml and then send it with the request. Specify the 'KeepRoot' parameter to
  # prevent XmlSimple from wrapping the xml with a spurious <opt> tag.
  args = [request_method, request_url]
  args << XmlSimple.xml_out(request_body, { 'KeepRoot' => true }) if request_body

  # Use Ruby's send method to invoke the appropriate method on request (get(), post(), or put()).
  # Note the splat (*) that dynamically expands the args array into a parameter list at runtime.
  response = request.send(*args)

  # Convert the raw xml from the response to the XmlSimple format and return it.
  XmlSimple.xml_in(response.body, { 'KeepRoot' => false })
end

# Connect to Parature's API for Recommender accounts
def recommender_requests(configuration, request_params, request_method, request_body = nil)

  base_url = URI.parse("https://#{configuration[:hostname]}/")

  request = Net::HTTP.new(base_url.host, base_url.port)
  request.use_ssl = true
  request.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request_url = "/api/v1/#{configuration[:account_id]}/#{configuration[:recommender_id]}/#{request_params}&_token_=#{configuration[:token]}"

  args = [request_method, request_url]
  args << XmlSimple.xml_out(request_body, { 'KeepRoot' => true }) if request_body

  response = request.send(*args)

  XmlSimple.xml_in(response.body, { 'KeepRoot' => false })
end

# Get Total Solved Applicant Tickets for Yesterday
dataSolvedApp = applicant_requests(configuration, "Ticket?_total_=true&Date_Created_min_=_last_month_&Ticket_Status_id_=7&Date_Updated_min_=#{Date.today.prev_day.strftime('%Y-%m-%d')}T05:00:00Z&Date_Updated_max_=#{Date.today.strftime('%Y-%m-%d')}T05:00:00Z", :get, nil)
solvedAppTickets = dataSolvedApp['total'].to_i

# Get Total Solved Applicant Chats for Yesterday
dataAppChat = applicant_requests(configuration, "Chat?_total_=yes&Date_Created_min_=#{Date.today.prev_day.strftime('%Y-%m-%d')}T05:00:00Z&Date_Created_max_=#{Date.today.strftime('%Y-%m-%d')}T01:00:00Z", :get, nil)
solvedAppChat = dataAppChat['total'].to_i

# Get Total Solved Recommender Tickets for Yesterday
dataSolvedRec = recommender_requests(configuration, "Ticket?_total_=true&Date_Created_min_=_last_month_&Date_Updated_max_=#{Date.today.strftime('%Y-%m-%d')}T05:00:00Z&Ticket_Status_id_=13&Date_Updated_min_=#{Date.today.prev_day.strftime('%Y-%m-%d')}T05:00:00Z", :get, nil)
solvedRecTickets = dataSolvedRec['total'].to_i

# Get Total Recommender Chats for Yesterday
dataRecChat = recommender_requests(configuration, "Chat?_total_=yes&Date_Created_min_=#{Date.today.prev_day.strftime('%Y-%m-%d')}T05:00:00Z&Date_Created_max_=#{Date.today.strftime('%Y-%m-%d')}T01:00:00Z", :get, nil)
solvedRecChat = dataRecChat['total'].to_i

# Calculate the Total Number of Yesterday's Tickets
yesterdaySolvedTickets = solvedAppTickets + solvedRecTickets

# Calculate the Total Number of Yesterday's Chats
yesterdaySolvedChats = solvedAppChat + solvedRecChat

#Send job information to widgets
send_event('yesterdaySolvedTickets', { current: yesterdaySolvedTickets } )
send_event('yesterdaySolvedChats', { current: yesterdaySolvedChats } )

end
