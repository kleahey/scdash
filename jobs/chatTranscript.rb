require 'rubygems'
require 'net/http'
require 'net/https'
require 'xmlsimple'
require 'pp'
require 'time'
require 'prawn'
require 'logger'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'mail'

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

SCHEDULER.cron '58 7 * * 0-6' do |job|

# Get a list of all chat IDs from Yesterday
applicantArray = []
recommenderArray = []

MyLog.log.info "Grabbing all Applicant Chat Numbers from yesterday."
applicantChat = applicant_requests($configuration, "Chat?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}&_pageSize_=200", :get, nil)

begin
  applicantChat["Chat"].map do |x|
    next if x["Chat_Number"][0]["content"].blank?

    if x["Chat_Number"][0]["content"] != 0
      applicantArray.push(x["Chat_Number"][0]["content"])
    end
  end
rescue => e
  MyLog.log.warn e
end

MyLog.log.info "Grabbing all Recommender Chat Numbers from yesterday."
recommenderChat = recommender_requests($configuration, "Chat?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}&_pageSize_=200", :get, nil)

begin
  recommenderChat["Chat"].map do |x|
    next if x["Chat_Number"][0]["content"].blank?

    if x["Chat_Number"][0]["content"] != 0
      recommenderArray.push(x["Chat_Number"][0]["content"])
    end
  end
rescue => e
  MyLog.log.warn e
end

appFixArray = []
recFixArray = []

MyLog.log.info "Checking Applicant Chat Transcript content"
begin
  applicantArray.each do |x|
    begin
      checkTranscript = applicant_requests($configuration, "Chat/#{x}/Transcript?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}", :get, nil)
    rescue => e
      MyLog.log.info e
    end

    checkTranscript.to_json

    begin
      next if checkTranscript["Message"][3]["Text"].blank?
      appFixArray.push(x)
    rescue => e
      MyLog.log.info e
    end
  end
end

MyLog.log.info "Checking Recommender Chat Transcript content"
begin
  recommenderArray.each do |x|
    begin
      checkTranscript = recommender_requests($configuration, "Chat/#{x}/Transcript?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}", :get, nil)
    rescue => e
      MyLog.log.info e
    end

    checkTranscript.to_json

    begin
      next if checkTranscript["Message"][3]["Text"].blank?
      recFixArray.push(x)
    rescue => e
      MyLog.log.info e
    end
  end
rescue => e
  MyLog.log.warn e
end

# Choose a random 10 chats from the pool of yesterday's IDs
MyLog.log.info "Grabbing random sample of Applicant Chat Numbers from yesterday."
newAppArray = appFixArray.sample(5)
MyLog.log.info "Grabbing random sample of Recommender Chat Numbers from yesterday."
newRecArray = recFixArray.sample(5)

Prawn::Document.generate("tmp/#{Date.today.prev_day.strftime("%Y-%m-%d")}_chatreport.pdf",
                          :page_size    => "LETTER",
                          :page_layout  => :portrait) do |pdf|

pdf.font("assets/fonts/Roboto-Regular.ttf")
pdf.text "Chat transcripts for #{Date.today.prev_day.strftime('%m-%d-%Y')}"
pdf.move_down 25

# Get the transcript from each applicant chat
begin
  newAppArray.each do |z|

    MyLog.log.info "Grabbing transcript for Applicant Chat Number #{z}."
    pdf.text "Applicant Chat Number #{z}:"
    pdf.move_down 25

    appTranscript = applicant_requests($configuration, "Chat/#{z}/Transcript?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}", :get, nil)
    appTranscript.to_json

    begin
      appTranscript["Message"].each do |x|
        pdf.formatted_text [ { :text => "#{x["Customer"] || x["Csr"]}", :color => "981a36"  } ]
        pdf.text "Timestamp: #{x["Timestamp"][0]}"
        pdf.move_down 3
        pdf.text "#{x["Text"][0]}"
        pdf.move_down 8
      end
    rescue => e
      MyLog.log.info e
    end

  pdf.start_new_page
end
rescue => e
  MyLog.log.info e
end

# Get the transcript from each recommender chat
begin
  newRecArray.each do |z|

    MyLog.log.info "Grabbing transcript for Recommender Chat Number #{z}."
    pdf.text "Recommender Chat Number #{z}:"
    pdf.move_down 25

    recTranscript = recommender_requests($configuration, "Chat/#{z}/Transcript?Date_Created=#{Date.today.prev_day.strftime('%Y-%m-%d')}", :get, nil)
    next if recTranscript.nil?

    recTranscript.to_json

    begin
      recTranscript["Message"].map do |x|
        next if x["Customer"].nil? && x["Csr"].nil?
        pdf.formatted_text [ { :text => "#{x["Customer"] || x["Csr"]}", :color => "981a36"  } ]
        pdf.text "Timestamp: #{x["Timestamp"][0]}"
        pdf.text "#{x["Text"][0]}"
        pdf.move_down 8
      end
    rescue => e
      MyLog.log.info e
    end

pdf.start_new_page
end
rescue => e
  MyLog.log.info e
end

end

gmailOptions = { :address              => "smtp.gmail.com",
                 :port                 => 587,
                 :domain               => 'commonapp.org',
                 :user_name            => 'kleahey@commonapp.org',
                 :password             => ENV['GMAIL_PASSWORD'],
                 :authentication       => 'plain',
                 :enable_starttls_auto => true  }

Mail.defaults do
  delivery_method :smtp, gmailOptions
end

begin
  Mail.deliver do
        to 'kleahey@me.com'
        from 'kleahey@commonapp.org'
        subject "Yesterday's Chat Report"
        body "Attached is the Chat Report for #{Date.today.prev_day.strftime("%Y-%m-%d")}"
        add_file "tmp/#{Date.today.prev_day.strftime("%Y-%m-%d")}_chatreport.pdf"
  end
rescue => e
  MyLog.log.info e
end

File.delete("tmp/#{Date.today.prev_day.strftime("%Y-%m-%d")}_chatreport.pdf")

end
