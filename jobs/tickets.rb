require 'mysql2'

SCHEDULER.every '5m', :first_in => 0 do |job|

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
  sql = "SELECT csr, (SUM(app)+SUM(rec)+SUM(mem)) AS totals FROM tickets WHERE date=(SELECT MAX(date) FROM tickets) GROUP BY csr HAVING (SUM(app)+SUM(rec)+SUM(mem)) > 0 ORDER BY totals DESC"

  # Execute the query
  results = db.query(sql)

  # Sending to List widget, so map to :label and :value
  ticketTotals = results.map do |row|
    row = {
      :label => row['csr'],
      :value => row['totals']
    }
  end

  # Update the List widget
  send_event('ticketsAnswered', { items: ticketTotals } )

end
