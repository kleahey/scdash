require 'net/http'
require 'rubygems'
require 'nokogiri'
require 'json'

SCHEDULER.every '5m', :first_in => 0 do |job|

url = 'https://feeds.capitalbikeshare.com/stations/stations.xml'
xml_data = Net::HTTP.get_response(URI.parse(url)).body
@x = 0
@y = 0
@z = 0

@doc = Nokogiri::XML(xml_data)
clarendon = @doc.xpath('//station[contains(id, "140")]')
clarendon.each do |a|
   @x = a.children[12].text
end

send_event('hobsons',   { value: @x })

@doc2 = Nokogiri::XML(xml_data)
fillmore = @doc2.xpath('//station[contains(id, "139")]')
fillmore.each do |b|
   @y = b.children[12].text
end

send_event('fillmore',   { value: @y })

@doc3 = Nokogiri::XML(xml_data)
fairfax = @doc3.xpath('//station[contains(id, "160")]')
fairfax.each do |c|
   @z = c.children[12].text
end

send_event('fairfax',   { value: @z })

end




#fillmore = @doc.xpath('//station[contains(id, "139")]')
#fillmore.each do |a|
#  print a.children[1].text
#  print ": \n"
#  print a.children[12].text + " bikes available.\n"
#  print a.children[13].text + " empty docks.\n"
#end

#fairfax = @doc.xpath('//station[contains(id, "160")]')
#fairfax.each do |a|
#  print a.children[1].text
#  print ": \n"
#  print a.children[12].text + " bikes available.\n"
#  print a.children[13].text + " empty docks.\n"
#end
