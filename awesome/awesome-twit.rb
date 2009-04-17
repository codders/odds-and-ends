#!/usr/bin/ruby

require 'net/http'
require 'yaml'
require 'rexml/document'
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
  config_obj = { "username" => "SETME",
                 "password" => "SETME" }
  write_config(config_obj)
  puts "Please edit config file #{CONFIGFILE}"
  exit 1
end

config = YAML.load_file(CONFIGFILE)

if not config.has_key?("username")
  puts "Please add a username to the config file"
  exit 1
end

if not config.has_key?("password")
  puts "Please add a password to the config file"
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

while true
  begin
    Net::HTTP.start('twitter.com') do |http|
      req = Net::HTTP::Get.new('/statuses/friends_timeline.xml')
      req.basic_auth config["username"], config["password"]
      response = http.request(req)
      if response.code != "200"
        puts "Error fetching document (#{response.code})"
        sleep 90
        next
      end
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

