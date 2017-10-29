require 'rubygems'
require 'net/http'
require 'net/https'
require 'xmlsimple'
require 'pp'
require 'time'
require 'prawn'
require 'logger'
require 'json'

class MyLog
  def self.log
    if @logger.nil?
      @logger = Logger.new STDOUT
      @logger.level = Logger::INFO
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S '
    end
    @logger
  end
end

$configuration =
{
  :hostname   => "d19.parature.com",
  :account_id => "33011",
  :token      => "Sn5wkZHGHZhwkHUvJ3OIvqhS0eyiZrHcOWNIrYrTh0In16VGnboqlREsm@mUFkbW7GxQQx7kcwGiSzHRlrnW6jlM1ZnN@8SdxKsZYHJt2fQ=",
  :applicant_id => "33013",
  :recommender_id => "33014"
}

def applicant_requests(configuration, request_params, request_method, request_body = nil)

  base_url = URI.parse("https://#{configuration[:hostname]}/")

  request = Net::HTTP.new(base_url.host, base_url.port)
  request.use_ssl = true
  request.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request_url = "/api/v1/#{configuration[:account_id]}/#{configuration[:applicant_id]}/#{request_params}&_token_=#{configuration[:token]}"

  args = [request_method, request_url]
  args << XmlSimple.xml_out(request_body, { 'KeepRoot' => true }) if request_body

  response = request.send(*args)

  XmlSimple.xml_in(response.body, { 'KeepRoot' => false })
end

# Connect to Parature's API for Recommender accounts
def recommender_requests(configuration, request_params, request_method, request_body = nil)

  base_url = URI.parse("https://#{configuration[:hostname]}/")

  request = Net::HTTP.new(base_url.host, base_url.port)
  request.use_ssl = true
  request.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request_url = "/api/v1/#{configuration[:account_id]}/#{configuration[:recommender_id]}/#{request_params}&_token_=#{configuration[:token]}"

  args = [request_method, request_url]
  args << XmlSimple.xml_out(request_body, { 'KeepRoot' => true }) if request_body

  response = request.send(*args)

  XmlSimple.xml_in(response.body, { 'KeepRoot' => false })
end

# Set the ID of the team member you are pulling tickets for
teamMember = "147"

# Get a list of all ticket IDs from Yesterday
applicantArray = []
recommenderArray = []
t = Date.today
u = Date.new(t.year, t.month, t.day) - 24
v = Date.new(t.year, t.month, t.day) - 1

MyLog.log.info "Grabbing all Applicant Ticket Numbers from the month."
applicantTickets = applicant_requests($configuration, "Ticket?Date_Created_min_=#{u.strftime('%Y-%m-%d')}&Date_Created_max_=#{v.strftime('%Y-%m-%d')}&Assigned_To_id_=#{teamMember}&_pageSize_=500", :get, nil)

begin
  applicantTickets["Ticket"].map do |x|
    applicantArray.push(x["id"])
  end
end

MyLog.log.info "Grabbing all Recommender Ticket Numbers from the month."
recommenderTickets = recommender_requests($configuration, "Ticket?Date_Created_min_=#{u.strftime('%Y-%m-%d')}&Date_Created_max_=#{v.strftime('%Y-%m-%d')}&Assigned_To_id_=#{teamMember}&_pageSize_=500", :get, nil)

begin
  # Push recommender ticket numbers to recommenderArray
  recommenderTickets["Ticket"].map do |x|
    recommenderArray.push(x["id"])
  end
end

allTickets = applicantArray.push(*recommenderArray)

# Choose a random 10 chats from the pool of yesterday's IDs
MyLog.log.info "Grabbing random sample of CSR's ticket Numbers from the month."
newAppArray = allTickets.sample(20)

Prawn::Document.generate("/Users/kleahey/Desktop/#{Time.now.strftime("%m-%d-%y")}") do |pdf|

  pdf.font_families.update("Roboto" => {
    :normal => "Roboto-Regular.ttf",
    :italic => "Roboto-Italic.ttf",
    :bold => "Roboto-Bold.ttf",
    :bold_italic => "Roboto-BoldItalic.ttf"
    })
  pdf.font ("Roboto")

# Get the transcript from each ticket
newAppArray.each do |z|

  MyLog.log.info "Grabbing Ticket #{z}."

  appTranscript = applicant_requests($configuration, "Ticket/#{z}?_history_=true", :get, nil)

  if appTranscript["code"] == '404'
    recTranscript = recommender_requests($configuration, "Ticket/#{z}?_history_=true", :get, nil)

    recTranscript.to_json

    pdf.text "Ticket #: 33011-#{recTranscript['id']}"
    pdf.text "Date Created: #{recTranscript['Date_Created'][0]['content']}"
    pdf.text "Assigned Tech: #{recTranscript['Assigned_To'][0]['Csr'][0]['Full_Name'][0]['content']}"
    pdf.text "Ticket SLA: #{recTranscript['Ticket_Sla'][0]["Sla"][0]["Name"][0]["content"]}"
    pdf.text "Response Time (Min): #{recTranscript['Initial_Response_Duration_Bh'][0]['content']}"
    pdf.text "Details: #{recTranscript['Custom_Field'][7]['content']}"
    pdf.text "Summary: #{recTranscript['Custom_Field'][2]['content']}"

    pdf.move_down 20

    recTranscript['ActionHistory'][0]['History'].each do |x|
      pdf.text "Action: #{x['Action'][0]['name']}"
      pdf.text "Old Status: #{x['Old_Status'][0]['Status'][0]['Name'][0]['content']}"
      pdf.text "New Status: #{x['New_Status'][0]['Status'][0]['Name'][0]['content']}"
      pdf.text "Action Performer: #{x['Action_Performer'][0]['performer-type']}"
      pdf.text "Action Target: #{x['Action_Target'][0]['target-type']}"
      pdf.text("Comments: #{x['Comments'][0]['content']}", :inline_format => true)

      pdf.move_down 20

    end

  else

    pdf.text "Ticket #: 33011-#{appTranscript['id']}"
    pdf.text "Date Created: #{appTranscript['Date_Created'][0]['content']}"
    pdf.text "Assigned Tech: #{appTranscript['Assigned_To'][0]['Csr'][0]['Full_Name'][0]['content']}"
    pdf.text "Ticket SLA: #{appTranscript['Ticket_Sla'][0]["Sla"][0]["Name"][0]["content"]}"
    pdf.text "Response Time (Min): #{appTranscript['Initial_Response_Duration_Bh'][0]['content']}"
    pdf.text "Details: #{appTranscript['Custom_Field'][7]['content']}"
    pdf.text "Summary: #{appTranscript['Custom_Field'][2]['content']}"

    pdf.move_down 20

    appTranscript['ActionHistory'][0]['History'].each do |x|
      pdf.text "Action: #{x['Action'][0]['name']}"
      pdf.text "Old Status: #{x['Old_Status'][0]['Status'][0]['Name'][0]['content']}"
      pdf.text "New Status: #{x['New_Status'][0]['Status'][0]['Name'][0]['content']}"
      pdf.text "Action Performer: #{x['Action_Performer'][0]['performer-type']}"
      pdf.text "Action Target: #{x['Action_Target'][0]['target-type']}"
      pdf.text("Comments: #{x['Comments'][0]['content']}", :inline_format => true)

      pdf.move_down 20

    end

  end

pdf.start_new_page

end

end
