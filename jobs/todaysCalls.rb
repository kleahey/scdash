require 'httparty'
require 'date'
require 'json'

view_url = "#{ENV["ACUITY_VIEW_URL"]}" + "#{Date.today.strftime('%Y-%m-%d')}" + "&maxDate=" + "#{Date.today.strftime('%Y-%m-%d')}"

class Acuity
  include HTTParty
  format :json
  base_uri ENV["ACUITY_URL"]
  basic_auth ENV["ACUITY_USERNAME"], ENV["ACUITY_PASSWORD"]
end

SCHEDULER.every '1h', :first_in => 1 do |job|

result = Acuity.get(view_url)

data = result.parsed_response

ticketTotals = data.map do |row|
    row = {
      :label => row['time'],
      :value => row['calendar']
    }
  end

ticketTotals.reverse!

send_event('todaysCalls', { items: ticketTotals })

end
