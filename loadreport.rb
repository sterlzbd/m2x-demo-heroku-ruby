#!/usr/bin/env ruby

require "m2x"
TIMEFORMAT = "%Y-%m-%d %H:%M:%S"
BPNAME = "loadreport-heroku"


puts "Starting loadreport.rb run"

APIKEY = File.read(File.join(File.dirname(__FILE__), 'm2x_api_key.txt')).strip

m2x = M2X.new(APIKEY)


# Test to see if our blueprint exists
loadreport_blueprint_exists = false
blueprints = m2x.blueprints.list()

lr_blueprint = nil

blueprints.json["blueprints"].each { |bp|
    if bp['name'] == BPNAME
        loadreport_blueprint_exists = true
        lr_blueprint = bp
    end
}

if not loadreport_blueprint_exists
    puts "About to create the blueprint..."
    lr_blueprint = m2x.blueprints.create(name: BPNAME, visibility: "private", description: "Load Report")
end

# Create the streams if they don't exist
m2x.feeds.update_stream(lr_blueprint["id"], "load_1m")
m2x.feeds.update_stream(lr_blueprint["id"], "load_5m")
m2x.feeds.update_stream(lr_blueprint["id"], "load_15m")

# Get our load data from the system
# Match `uptime` load averages output for both Linux and OSX
UPTIME_RE = /(\d+\.\d+),? (\d+\.\d+),? (\d+\.\d+)$/
load_1m, load_5m, load_15m = `uptime`.match(UPTIME_RE).captures

# Write the different values into AT&T M2X
now = Time.now.iso8601

values = {
  load_1m:  [ { value: load_1m, at: now } ],
  load_5m:  [ { value: load_5m, at: now } ],
  load_15m: [ { value: load_15m, at: now } ]
}

m2x.feeds.post_multiple(lr_blueprint["id"], values)

puts "Ending loadreport.rb run"
