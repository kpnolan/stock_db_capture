require 'eventmachine'
require 'em-http'
require 'fiber'

# Using Fibers in Ruby 1.9 to simulate blocking IO / IO scheduling
# while using the async EventMachine API's

def async_fetch(url)
  f = Fiber.current
  http = EventMachine::HttpRequest.new(url).get :timeout => 10
  puts 'starting request'
  http.callback { f.resume(http) }
  http.errback  { f.resume(http) }
  puts 'b4 Fiber.yield'
  return Fiber.yield
end

EventMachine.run do
  Fiber.new{
    url1 = 'http://www.pdxtelco.org/'
    url2 = 'http://stackoverflow.com/questions/1109695/installing-ruby-1-9-1-on-ubuntu'
    puts "Setting up HTTP request #1"
    data = async_fetch(url1)
    puts "Fetched page #1: #{data.response_header.status}"

    puts "Setting up HTTP request #2"
    data = async_fetch(url1)
    puts "Fetched page #2: #{data.response_header.status}"

    puts "Setting up HTTP request #2"
    data = async_fetch(url2)
    puts "Fetched page #2: #{data.response_header.status}"

    EventMachine.stop
  }.resume
  puts "end of EM"
end

puts "Done"
