require 'mysql2'

SCHEDULER.every '2m', :first_in => 0 do |job|

  # Myql connection
  db = Mysql2::Client.new(:host => "localhost", :username => "root", :password => "Planet@ry7", :port => 3306, :database => "moodledb" )

  # Mysql query
  sql = "SELECT content FROM mdl_data_content WHERE fieldid = 64 AND recordid=(SELECT MAX(recordid) FROM mdl_data_content WHERE fieldid = 64)"

  # Execute the query
  results = db.query(sql)

  your_row = results.first['content']

  # Update the List widget
  send_event('welcome', { text: your_row } )

end
