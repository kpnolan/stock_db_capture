#!/usr/bin/env ruby

require 'rubygems'
require 'mq'

AMQP.start(:host => 'localhost') {
  amq = MQ.new
  queue = amq.queue("counts3")
  $stime = Time.now
  i = 0
  EM.add_periodic_timer(0.1) do
    10_000.times do
      queue.publish(i.to_s)
      puts "published #{i}"
      if (i+=1) > 9999
        queue.publish(-1.to_s)
        AMQP.stop {  EM.stop }
      end
    end
  end
  $etime = Time.now
}
puts "producer finished in #{$etime-$stime} seconds"
