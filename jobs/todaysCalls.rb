require 'httparty'
require 'date'

#Enter the Acuity API information
ACUITY_URL = 'https://acuityscheduling.com/api/v1/appointments'
ACUITY_VIEW_URL = 'https://acuityscheduling.com/api/v1/appointments?minDate=' + Date.today.strftime('%Y-%m-%d') + '&maxDate=' + Date.today.strftime('%Y-%m-%d')
ACUITY_USERNAME = '11579503'
ACUITY_PASSWORD = '9cd81dfd631902bcc731e2711f2cc7a2'

SCHEDULER.every '10s', :first_in => 4 do |job|

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
      :label => row['time'],
      :value => row['calendar']
    }
  end

  HTTParty.post("https://api.hipchat.com/v2/room/421939/notification",
    :query => {
      :color => "yellow",
      :message => "<strong>Please check the Briefing Board for updates!</strong>",
      :notify => "true",
      :message_format => "html"
    },
    :headers => {
      :Authorization => "Bearer im2tvoAJxRBa9Z8XP9FK6Ke82x1esTora650bhEu"
    })

send_event('todaysCalls', { items: ticketTotals })

end
