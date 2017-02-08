require 'net/http'
require 'json'

SCHEDULER.every '1m', :first_in => 0 do |job|

uri = URI('https://api.wmata.com/StationPrediction.svc/json/GetPrediction/K02')

request = Net::HTTP::Get.new(uri.request_uri)
# Request headers
request['api_key'] = 'b70a8fc0f6964bc4a8e416c651168af9'
# Request body
request.body = "{body}"

response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request(request)
end

parsed = JSON.parse(response.body)

data = parsed['Trains']

textBox = data.map do |row|
  row = {
    :label =>
      if row['Destination']=="NewCrltn"
        'New Carrollton'
      else
        row['Destination']
      end,
    :value => row['Min'] +
      if row['Min']=="BRD"||row['Min']=="ARR"
        ''
      else
        ' min'
      end
  }
end

send_event('railinfo', { items: textBox })

end
