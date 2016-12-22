require 'mysql2'

SCHEDULER.every '10s', :first_in => 0 do |job|

  # Myql connection
  db = Mysql2::Client.new(:host => "cauniversity.net", :username => "root", :password => "Planet@ry7", :port => 3306, :database => "SATA" )

  # Mysql query
  sql = "SELECT SUM(app+rec+mem) AS totals FROM tickets WHERE date BETWEEN CURDATE() - INTERVAL 1 DAY AND CURDATE()"

  sql2 = "SELECT SUM(app+rec+mem) AS totals FROM tickets WHERE date BETWEEN CURDATE() - INTERVAL 2 DAY AND CURDATE()"

  # Execute the query
  results = db.query(sql)
  results2 = db.query(sql2)

  your_row = results.first['totals']
  your_row2 = results2.first['totals']

  # Update the List widget
  send_event('ticketTotals', { current: your_row, last: your_row2 } )

end
