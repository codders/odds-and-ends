#!/usr/bin/ruby

require 'net/http'
require 'yaml'
require 'rexml/document'
require 'rubygems'
require 'oauth'
require 'oauth/consumer'
require 'builder'
include REXML

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
  return "mychatbox.text='#{data.to_xs.gsub(/'/, "&apos;")}'\n"
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

consumer = OAuth::Consumer.new(config["consumer_key"], config["consumer_secret"], { :site => "http://twitter.com" } )
if !config.has_key?("access_token")
  puts "No access token defined. Requesting..."
  request_token = consumer.get_request_token
  puts "Please visit #{request_token.authorize_url}"
  puts "... and enter the PIN provided:"
  pin = gets.chomp
  access_token = request_token.get_access_token(:oauth_verifier => pin)
  puts "Saving access token"
  config["access_token"] = access_token.token
  config["access_secret"] = access_token.secret
  write_config(config)
else
  puts "Using saved access token"
  access_token = OAuth::AccessToken.from_hash(consumer, { :oauth_token => config["access_token"], :oauth_token_secret => config["access_secret"] })
end
puts "Token: #{access_token.token} Secret: #{access_token.secret}"

while true
  begin
    response = access_token.get('/statuses/friends_timeline.xml')
    if response.code != "200"
      puts "Error fetching document (#{response.code})"
    else
      doc = Document.new response.body
      status = XPath.first(doc, '/statuses/status')
      user = XPath.first(status, 'user/screen_name').text
      text = XPath.first(status, 'text').text
      id = XPath.first(status, 'id').text
      if not config.has_key?("last_id") or config["last_id"] != id
        write_to_pipe("awesome-client", "<#{user}> #{text}")
      end
      config["last_id"] = id
      write_config(config) 
    end
  rescue
    puts "Error reading from network"
    sleep 90
    retry
  end
  sleep 90
end

