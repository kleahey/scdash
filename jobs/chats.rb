require 'mysql2'

SCHEDULER.every '1m' do

  # Myql connection
  db = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "Planet@ry7", :port => 3306, :database => "SATA" )

  # Mysql query
  sql = "SELECT csr, (SUM(appchat)+SUM(recchat)+SUM(memchat)) AS totals FROM tickets WHERE date=(SELECT MAX(date) FROM tickets) GROUP BY csr HAVING (SUM(appchat)+SUM(recchat)+SUM(memchat)) > 0 ORDER BY totals DESC"

  # Execute the query
  results = db.query(sql)

  # Sending to List widget, so map to :label and :value
  chatTotals = results.map do |row|
    row = {
      :label => row['csr'],
      :value => row['totals']
    }
  end

  # Update the List widget
  send_event('chatsAnswered', { items: chatTotals } )

end
