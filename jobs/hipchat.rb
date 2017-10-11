# HTTParty.post("https://api.hipchat.com/v2/room/421939/notification",
#   :query => {
#     :color => "yellow",
#     :message => "<strong>Please check the Briefing Board for updates!</strong>",
#     :notify => "true",
#     :message_format => "html"
#   },
#   :headers => {
#     :Authorization => "Bearer im2tvoAJxRBa9Z8XP9FK6Ke82x1esTora650bhEu"
#   })

require "hipchat"
require "json"
require "time"

SCHEDULER.every '1m', :first_in => 0 do |job|

  client = HipChat::Client.new("qPfNioZgUtyMxsqOhtvyATwqRBfxUmoc5ikj4fwz")

  result = client['DevDash'].history()

  result = JSON.parse(result)

  message = []

  result["items"].map do |x|
    message.push(x["message"])
  end

  welcome = message.last

  send_event('dailyBriefing', {text: welcome})

end
