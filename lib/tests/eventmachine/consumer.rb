#!/usr/bin/env ruby

require 'rubygems'
require 'mq'

AMQP.start(:host => 'localhost') {
  amq = MQ.new
  $stime = Time.now
  amq.queue("counts2").subscribe() do |i|
     puts "consumed #{i}"
     i = i.to_i
     AMQP.stop {  EM.stop } if i < 0
   end
  $etime = Time.now
}
puts "consumer finished in #{$etime-$stime} seconds"
