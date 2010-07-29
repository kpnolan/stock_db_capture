require 'eventmachine'
require 'em-http-request'
require 'em-synchrony'

def http_get(url)
  f = Fiber.current
  http = EventMachine::HttpRequest.new(url).get

  # resume fiber once http call is done
  http.callback { f.resume(http) }
  http.errback  { f.resume(http) }

  return Fiber.yield
end

EventMachine.run do
  Fiber.new{
    page = http_get('http://www.google.com/')
    puts "Fetched page: #{page.response_header.status}"

    if page
      page = http_get('http://www.google.com/search?q=eventmachine')
      puts "Fetched page 2: #{page.response_header.status}"
    end
  }.resume
end


