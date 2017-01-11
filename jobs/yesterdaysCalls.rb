require 'httparty'
require 'date'

#Enter the Acuity API information
ACUITY_URL = 'https://acuityscheduling.com/api/v1/appointments'
ACUITY_VIEW_URL = 'https://acuityscheduling.com/api/v1/appointments?minDate=' + Date.today.prev_day.strftime('%Y-%m-%d') + '&maxDate=' + Date.today.prev_day.strftime('%Y-%m-%d')
ACUITY_USERNAME = '11579503'
ACUITY_PASSWORD = '9cd81dfd631902bcc731e2711f2cc7a2'

SCHEDULER.every '1h', :first_in => 1 do |job|

class Acuity
  include HTTParty
  format :json
  base_uri ACUITY_URL
  basic_auth ACUITY_USERNAME, ACUITY_PASSWORD
end

result = Acuity.get(ACUITY_VIEW_URL)

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
