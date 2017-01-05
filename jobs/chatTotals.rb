require 'mysql2'

SCHEDULER.every '7m', :first_in => 0 do |job|

  # Myql connection
  db = Mysql2::Client.new(
                            :host => "ec2-52-10-206-237.us-west-2.compute.amazonaws.com",
                            :username => "sata",
                            :password => "Planet@ry7",
                            :port => 3306,
                            :database => "SATA",
                            :sslverify => true,
                            :sslkey => './config/webserver.pem'
                            )
  # Mysql query
  sql = "SELECT SUM(appchat+recchat+memchat) AS totals FROM tickets WHERE date BETWEEN CURDATE() - INTERVAL 1 DAY AND CURDATE()"

  sql2 = "SELECT SUM(appchat+recchat+memchat) AS totals FROM tickets WHERE date BETWEEN CURDATE() - INTERVAL 2 DAY AND CURDATE()"
  # Execute the query
  results = db.query(sql)
  results2 = db.query(sql2)

  your_row = results.first['totals']
  your_row2 = results2.first['totals']

  # Update the List widget
  send_event('totalChats', { current: your_row, last: your_row2 } )

end
