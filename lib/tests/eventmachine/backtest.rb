require 'eventmachine'
require 'mq'
require 'amqp'

1.times do
  EM.fork_reactor do
    exch = MQ.topic("tasks")
    keys = ['task1', 'task2', 'task3', 'task4']

    EM.add_timer(30) { EM.stop_event_loop }

    #EM.add_timer(0.1) do # do once!
#    EM.add_periodic_timer(0.1) do # every second
      #EM.defer do
        sec = 0#sleep(rand(3))
        key = keys[rand(4)]
        exch.publish("[#{Process.pid}] slept: #{sec} data for task: #{key}", :routing_key => key)
      #end
    #end

    keys.each do |key|
      MQ.queue(key).bind(exch, :key => key).subscribe do |msg|
        puts msg
        EM.defer do
          sec = 0 #sleep(rand(3))
          key = keys[rand(4)]
          exch.publish("[#{Process.pid}] slept: #{sec} data for task: #{key}", :routing_key => key)
        end
      end
    end
  end
end

p Process.waitall
