require 'rubygems'
require 'em-synchrony'
require 'addressable/uri'
load '/work/staging/em-synchrony/lib/em-synchrony/em-http.rb'

uri =  Addressable::URI::parse("http://www.google.com")

   EventMachine.synchrony do
  page = EventMachine::HttpRequest.new("http://www.google.com").get

  p "No callbacks! Fetched page: #{page}"
  EventMachine.stop
end
