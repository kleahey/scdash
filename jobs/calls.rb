require 'mysql2'

SCHEDULER.every '15m', :first_in => 0 do |job|

  # Myql connection
  db = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "Planet@ry7", :port => 3306, :database => "SATA" )

  # Mysql query
  sql = "SELECT
	    csr,calls,date
	FROM
	    tickets
	WHERE
	    date=(SELECT MAX(date) FROM tickets)
	AND
    	    calls > 0
	ORDER BY
    	    calls DESC"

  # Execute the query
  results = db.query(sql)

  # Sending to List widget, so map to :label and :value
  callTotals = results.map do |row|
    row = {
      :label => row['csr'],
      :value => row['calls']
    }
  end

  # Update the List widget
  send_event('scheduledCalls', { items: callTotals } )

end
