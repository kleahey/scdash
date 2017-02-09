require 'mysql2'


SCHEDULER.every '2m', :first_in => 0 do |job|

  # Myql connection
  db = Mysql2::Client.new(
                            :host => "ec2-52-10-206-237.us-west-2.compute.amazonaws.com",
                            :username => "sata",
                            :password => "Planet@ry7",
                            :port => 3306,
                            :database => "moodledb",
                            :sslverify => true,
                            :sslkey => './config/webserver.pem'
                            )

  # Mysql query
  sql = "SELECT Person.content AS 'NAME', Kudos.content AS 'KUDOS'
        FROM `mdl_data_content` Person
        JOIN `mdl_data_content` Kudos
        ON Person.recordid=Kudos.recordid
        AND Person.fieldid = '65'
        WHERE Kudos.fieldid = '66'"

  # Execute the query
  results = db.query(sql)

  kudos = results.map do |x|
    x = {
      :name => x['NAME'],
      :body => x['KUDOS'].gsub(/<\/?[^>]*>/, "")
    }
  end

  send_event('kudos', comments: kudos)

end
