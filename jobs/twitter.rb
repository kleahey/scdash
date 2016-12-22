require 'twitter'


#### Get your twitter keys & secrets:
#### https://dev.twitter.com/docs/auth/tokens-devtwittercom
twitter = Twitter::REST::Client.new do |config|
  config.consumer_key = 'zNRpcjxWtUR7C7eoTBBOMJfrC'
  config.consumer_secret = 'jhpyRO302xkz8lt7oW85O4Fg5IpPRCjGIR3Cj4T4hQmyzV3gxX'
  config.access_token = '21102961-rTCd2ccf8iIeOQTBwRR3r61FAjOXZJh3o7Edu9Cdh'
  config.access_token_secret = 'uhIwwDn4m8WHog7yGTxovRTzw97FmmPfdKmtds2ku1uFu'
end

search_term = URI::encode('@CommonApp')

SCHEDULER.every '10m', :first_in => 0 do |job|
  begin
    tweets = twitter.search("#{search_term}")

    if tweets
      tweets = tweets.map do |tweet|
        { name: tweet.user.name, body: tweet.text, avatar: tweet.user.profile_image_url_https }
      end
      send_event('twitter_mentions', comments: tweets)
    end
  rescue Twitter::Error
    puts "\e[33mFor the twitter widget to work, you need to put in your twitter API keys in the jobs/twitter.rb file.\e[0m"
  end
end
