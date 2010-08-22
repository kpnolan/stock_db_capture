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
