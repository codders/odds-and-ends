#!/usr/bin/ruby

require 'net/http'
require 'yaml'
require 'rexml/document'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'json'

PIDFILE = "#{ENV['HOME']}/var/run/awesome_twit.pid"
CONFIGFILE="#{ENV['HOME']}/.twit"

def read_file_contents(filename)
    f = File.new(filename, "r")
    data = f.gets
    f.close()
    return data.strip
end

def write_file_contents(filename, data)
    f = File.new(filename, "w")
    f.write(data)
    f.close()
end

def awesome_print(data)
  "mychatbox.text='#{data.split("\n").join(" ").gsub(/&/, "&amp;").gsub(/'/, "&apos;").gsub(/</, "&lt;").gsub(/>/, "&gt;").gsub(/"/, "&quot;")}'\n"
end

def write_to_pipe(command, data)
  f = IO.popen(command, "w")
  puts data
  printed = awesome_print(data)
  f.write(awesome_print(data))
  f.close()
end

def write_config(config)
  File.open(CONFIGFILE, 'w') do |out|
    YAML.dump(config, out)
  end
end

if not File.exists?(CONFIGFILE)
  config_obj = { "consumer_key" => "SETME",
                 "consumer_secret" => "SETME" }
  write_config(config_obj)
  puts "Please edit config file #{CONFIGFILE}"
  exit 1
end

config = YAML.load_file(CONFIGFILE)
if not config
  puts "Config file invalid"
  exit 1
end

if not config.has_key?("consumer_key")
  puts "Please add a consumer key to the config file"
  exit 1
end

if not config.has_key?("consumer_secret")
  puts "Please add a consumer secret to the config file"
  exit 1
end

if File.exists?(PIDFILE)
    pid = read_file_contents(PIDFILE)
    if system("kill -0 #{pid} 2> /dev/null")
      puts "Already running"
      exit 1
    else
      puts "Removed bogus lock file"
    end
end
write_file_contents(PIDFILE, "#{$$}\n")

consumer = OAuth::Consumer.new(config["consumer_key"], config["consumer_secret"], { :site => "https://api.twitter.com", :scheme => :header } )
token_hash = { :oauth_token => config["access_token"],
               :oauth_token_secret => config["access_secret"] }
access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
puts "Token: #{access_token.token} Secret: #{access_token.secret}"

while true
  begin
    response = access_token.request(:get, "/1.1/statuses/home_timeline.json")
    if response.code != "200"
      puts "Error fetching document (#{response.code})"
    else
      tweets = JSON.parse(response.body)
      tweet = tweets.first
      user = tweet["user"]["screen_name"]
      text = tweet["text"]
      id = tweet["id"]
      if not config.has_key?("last_id") or config["last_id"] != id
        write_to_pipe("awesome-client", "<#{user}> #{text}")
        config["last_id"] = id
        write_config(config) 
      end
    end
  rescue => e
    puts "Error reading from network: #{e}"
    sleep 90
    retry
  end
  sleep 90
end

