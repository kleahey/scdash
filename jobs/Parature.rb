require 'rubygems'
require 'net/http'
require 'net/https'
require 'xmlsimple'
require 'pp'
require 'time'
require 'figaro'

$configuration =
{
  :hostname   => "d19.parature.com",
  :account_id => "33011",
  :token      => "Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=",
  :applicant_id => "33013", # ID for a specific example customer you want to use
  :recommender_id => "33014"  # ID for a specific example CSR you want to use
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


# Get active Applicant tickets
dataApp = applicant_requests($configuration, 'Ticket?_total_=true&_status_type_=open', :get, nil)
activeAppTickets = dataApp['total'].to_i - 6

# Get Total Solved Applicant Tickets for Today
dataSolvedApp = applicant_requests($configuration, "Ticket?_total_=true&Date_Created_min_=_last_week_&Ticket_Status_id_=7&Date_Updated_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z", :get, nil)
solvedAppTickets = dataSolvedApp['total'].to_i

# Get Total Solved Applicant Chats for Today
dataAppChat = applicant_requests($configuration, "Chat?_total_=yes&Date_Created_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z&Date_Ended_min_=_today_", :get, nil)
solvedAppChat = dataAppChat['total'].to_i

# Get active Recommender tickets
dataRec = recommender_requests($configuration, 'Ticket?_total_=true&_status_type_=open', :get, nil)
activeRecTickets = dataRec['total'].to_i - 4

# Get Total Solved Recommender Tickets for Today
dataSolvedRec = recommender_requests($configuration, "Ticket?_total_=true&Date_Created_min_=_last_week_&Ticket_Status_id_=13&Date_Updated_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z", :get, nil)
solvedRecTickets = dataSolvedRec['total'].to_i

# Get Total Recommender Chats for Today
dataRecChat = recommender_requests($configuration, "Chat?_total_=yes&Date_Created_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z&Date_Ended_min_=_today_", :get, nil)
solvedRecChat = dataRecChat['total'].to_i

# Calculate the Total Number of Today's Chats
totalSolvedChats = solvedAppChat + solvedRecChat

# Calculate the Total Number of Today's Interactions
totalInteractions = solvedAppTickets + solvedRecTickets + totalSolvedChats

# List all solved ticket totals by Team Member
array = []

applicant = applicant_requests($configuration, "Ticket?_total_=false&Date_Created_min_=_last_week_&Ticket_Status_id_=7&Date_Updated_min_=#{Time.now.strftime('%Y-%m-%d')}T04:00:00Z&_pageSize_=200", :get, nil)
applicant['Ticket'].map do |x|
  array.push(x["Assigned_To"][0]["Csr"][0]["Full_Name"][0]["content"])
end

recommender = recommender_requests($configuration, "Ticket?_total_=false&Date_Created_min_=_last_week_&Ticket_Status_id_=13&Date_Updated_min_=#{Time.now.strftime('%Y-%m-%d')}T04:00:00Z&_pageSize_=200", :get, nil)
recommender['Ticket'].map do |x|
  array.push(x["Assigned_To"][0]["Csr"][0]["Full_Name"][0]["content"])
end

counts = Hash.new(0)
array.each { |array| counts[array] += 1 }

counts = counts.sort_by { |k, v| v }.reverse
ticketTotals = counts.map do |k, v|
  row = {
    :label => k,
    :value => v
  }
end

# List all chat totals by Team Member
chat_array = []

applicant_chat = applicant_requests($configuration, "Chat?_total_=false&Date_Created_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z&Date_Ended_min_=_today_", :get, nil)

begin
  applicant_chat['Chat'].map { |x| chat_array.push(x["Initial_Csr"][0]["Csr"][0]["Full_Name"][0]["content"]) }
rescue
  puts "Error reading Applicant chats."
end

recommender_chat = recommender_requests($configuration, "Chat?_total_=false&Date_Created_min_=#{Time.now.strftime('%Y-%m-%d')}T05:00:00Z&Date_Ended_min_=_today_", :get, nil)

begin
  recommender_chat['Chat'].each { |x| chat_array.push(x["Initial_Csr"][0]["Csr"][0]["Full_Name"][0]["content"]) }
rescue
  puts "Error reading Recommender chats."
end

chat_counts = Hash.new(0)
chat_array.each { |array| chat_counts[array] += 1 }

chat_counts = chat_counts.sort_by { |k, v| v }.reverse
chatTotals = chat_counts.map { |k, v| row = { :label => k, :value => v } }

#Send job information to widgets
send_event('activeAppTickets', { value: activeAppTickets } )
send_event('activeRecTickets', { value: activeRecTickets } )
send_event('solvedAppTickets', { current: solvedAppTickets } )
send_event('solvedRecTickets', { current: solvedRecTickets } )
send_event('totalSolvedChats', { current: totalSolvedChats } )
send_event('totalInteractions', { current: totalInteractions } )
send_event('ticketsAnswered', { items: ticketTotals } )
send_event('chatsAnswered', { items: chatTotals } )

end
