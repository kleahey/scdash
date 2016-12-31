require 'httparty'
require 'xmlsimple'

SCHEDULER.every '15s', :first_in => 0 do |job|

#Get Active Applicant Tickets
responseApp = HTTParty.get('https://d19.parature.com/api/v1/33011/33013/Ticket?_total_=true&_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&_status_type_=open')
dataApp = XmlSimple.xml_in(responseApp.body, { 'KeepRoot' => false })
activeAppTickets = dataApp['total']
activeAppTickets = activeAppTickets.to_i - 5

#Pause for API
sleep(1)

#Get Active Recommender Tickets
responseRec = HTTParty.get('https://d19.parature.com/api/v1/33011/33014/Ticket?_total_=true&_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&_status_type_=open')
dataRec = XmlSimple.xml_in(responseRec.body, { 'KeepRoot' => false })
activeRecTickets = dataRec['total']
activeRecTickets = activeRecTickets.to_i - 4

#Pause for API
sleep(1)

#Get Total Solved Applicant Tickets for Today
solvedApp = HTTParty.get('https://d19.parature.com/api/v1/33011/33013/Ticket?_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&Date_Updated_min_=_today_&Ticket_Status_id_=7&_total_=true&Date_Created_min_=_last_week_')
dataSolvedApp = XmlSimple.xml_in(solvedApp.body, { 'KeepRoot' => false })
solvedAppTickets = dataSolvedApp['total']
solvedAppTickets = solvedAppTickets.to_i - 5

#Pause for API
sleep(1)

#Get Total Solved Recommender Tickets for Today
solvedRec = HTTParty.get('https://d19.parature.com/api/v1/33011/33014/Ticket?_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&Date_Updated_min_=_today_&Ticket_Status_id_=13&_total_=true&Date_Created_min_=_last_week_')
dataSolvedRec = XmlSimple.xml_in(solvedRec.body, { 'KeepRoot' => false })
solvedRecTickets = dataSolvedRec['total']
solvedRecTickets = solvedRecTickets.to_i - 4

#Pause for API
sleep(1)

#Get Total Solved Applicant Chats for Today
appChat = HTTParty.get('https://d19.parature.com/api/v1/33011/33013/Chat?_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&Date_Created_min_=_today_&_total_=false&Date_Ended_min_=_today_')
dataAppChat = XmlSimple.xml_in(appChat.body, { 'KeepRoot' => false })
solvedAppChat = dataAppChat['total']
solvedAppChat = solvedAppChat.to_i - 33

#Pause for API
sleep(1)

#Get Total Solved Recommender Chats for Today
recChat = HTTParty.get('https://d19.parature.com/api/v1/33011/33014/Chat?_token_=Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=&Date_Created_min_=_today_&_total_=false&Date_Ended_min_=_today_')
dataRecChat = XmlSimple.xml_in(recChat.body, { 'KeepRoot' => false })
solvedRecChat = dataRecChat['total']
solvedRecChat = solvedRecChat.to_i - 2

totalSolvedChats = solvedAppChat + solvedRecChat

totalInteractions = solvedAppTickets + solvedRecTickets + totalSolvedChats

#Send job information to widgets
send_event('activeAppTickets', { value: activeAppTickets } )
send_event('activeRecTickets', { value: activeRecTickets } )
send_event('solvedAppTickets', { current: solvedAppTickets } )
send_event('solvedRecTickets', { current: solvedRecTickets } )
send_event('totalSolvedChats', { current: totalSolvedChats } )
send_event('totalInteractions', { current: totalInteractions } )

end
