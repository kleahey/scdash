require 'net/http'
require 'json'

SCHEDULER.every '15m', :first_in => 0 do |job|

uri = URI('https://api.wmata.com/Incidents.svc/json/Incidents')

request = Net::HTTP::Get.new(uri.request_uri)
# Request headers
request['api_key'] = 'b70a8fc0f6964bc4a8e416c651168af9'
# Request body
request.body = "{body}"

response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request(request)
end

parsed = JSON.parse(response.body)

data = parsed["Incidents"]

output = data.map do |row|
  row = {
    :label => row["Description"] + "\n"
  }
end

send_event('railincidents', { items: output } )

end
