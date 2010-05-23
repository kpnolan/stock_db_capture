require 'rubygems'
require 'mq'
require 'pp'

Signal.trap('INT') { AMQP.stop{ EM.stop } }
Signal.trap('TERM'){ AMQP.stop{ EM.stop } }

AMQP.start do
  queue = MQ.queue('awesome')

  queue.publish('Totally rad 1')
  queue.publish('Totally rad 2')
  EM.add_timer(5){ queue.publish('Totally rad 3') }

  queue.pop(){ |msg|
    unless msg
      # queue was empty
      p [Time.now, :queue_empty!]

      # try again in 1 second
      EM.add_timer(1){ queue.pop }
    else
      # process this message
      p [Time.now, msg]

      # get the next message in the queue
      queue.pop
    end
  }
end
