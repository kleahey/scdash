require 'httparty'
require 'date'

view_url = "#{ENV["ACUITY_VIEW_URL"]}" + "#{Date.today.prev_day.strftime('%Y-%m-%d')}" + "&maxDate=" + "#{Date.today.prev_day.strftime('%Y-%m-%d')}"

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
      :label => row['calendar'],
      :value => row['time']
    }
  end
  ticketTotals.reverse!

send_event('yesterdaysCalls', { items: ticketTotals })

end
