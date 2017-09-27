require 'httparty'
require 'date'
require 'json'

view_url = "https://acuityscheduling.com/api/v1/appointments?minDate=" + "#{Date.today.strftime('%Y-%m-%d')}" + "&maxDate=" + "#{Date.today.strftime('%Y-%m-%d')}"

class Acuity
  include HTTParty
  format :json
  base_uri "https://acuityscheduling.com/api/v1/appointments"
  basic_auth "11579503", "9cd81dfd631902bcc731e2711f2cc7a2"
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

send_event('todaysCalls', { items: ticketTotals })

end
