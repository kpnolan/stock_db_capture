require "rubygems"
require "eventmachine"
require "mq"
require "amqp"

# comment out one of these to pick communication model
PUBLISH_MODE = :one_to_n
#PUBLISH_MODE = :one_to_one_of_n

START_TIME = Time.new

def finish
  EM.forks.each {|pid| Process.kill("KILL", pid)}
  EM.stop { AMQP.stop }
end

def gen_queue_name
  if PUBLISH_MODE == :one_to_n
    rand(2 ** 16).to_s(16)
  else
    "foobarbaz"
  end
end

def timestamp
  delta_t = Time.new - START_TIME
  delta_t.to_s
end

EM.fork(3) do
  mq = MQ.new
  qname = gen_queue_name
  puts "starting queue ``#{qname}'', PID: #{Process.pid.to_s}"
  q = mq.queue(qname).bind(mq.topic("test"), :key => "test.key")
  q.subscribe do |msg|
    puts "[queue #{qname} (pid #{Process.pid.to_s})] received msg: #{msg} @ #{timestamp}"
  end
end

AMQP.start do
  i = 0
  topic = MQ.new.topic("test")
  EM.add_periodic_timer(0.1) do
    i += 1
    topic.publish("[#{i}] " + timestamp, :key => "test.key")
    finish if i >= 1000
  end
end
