#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
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
