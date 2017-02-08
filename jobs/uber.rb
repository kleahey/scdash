require 'net/http'
require 'uri'
require 'json'

SCHEDULER.every '60s', :first_in => 0 do |job|

uri = URI.parse("https://api.uber.com/v1.2/estimates/time?start_latitude=38.885939&start_longitude=-77.094258")
request = Net::HTTP::Get.new(uri)
request.content_type = "application/json"
request["Authorization"] = "Token rAT6_iCDFjaej-T8uOoVtdWcbSPUD4HASjWGQSmY"
request["Accept-Language"] = "en_US"

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

parsed = JSON.parse(response.body)

data = parsed['times']

x = data.map do |row|
  q = row['estimate'].to_i / 60
  row = {
    :label => row['display_name'],
    :value => q.to_s + " min"
  }
end

send_event('uberTime', { items: x } )

end
