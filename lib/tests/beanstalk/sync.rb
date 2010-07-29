require 'beanstalk-client'
require 'thread'

msg = Marshal.dump(Array.new(16) { |i| i })

pubcon = Beanstalk::Connection.new('127.0.0.1:11300')
concon = Beanstalk::Connection.new('127.0.0.1:11300')
msglen = msg.length
count = 100_000

startt = Time.now

producer = Thread.new do
  count.times do
    pubcon.put(msg)
  end
end

consumer = Thread.new do
  count.times do
    job = concon.reserve
    job.delete
  end
end

consumer.join

dt = Time.now-startt

puts "#{count} messages of length #{msglen} in #{dt} seconds #{count/dt} messages/sec"

pubcon.close
concon.close



