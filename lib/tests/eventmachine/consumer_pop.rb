#!/usr/bin/env ruby

require 'rubygems'
require 'mq'

AMQP.start(:host => 'localhost') {
  amq1 = MQ.queue('count1')
  amq2 = MQ.queue('count2')
  $stime = Time.now
  amq1.pop do |i|
     puts "consumed #{i}"
     i = i.to_i
     AMQP.stop {  EM.stop } if i < 0
   end
  amq2.pop do |i|
     puts "consumed #{i}"
     i = i.to_i
     AMQP.stop {  EM.stop } if i < 0
   end
  $etime = Time.now
}
puts "consumer finished in #{$etime-$stime} seconds"
