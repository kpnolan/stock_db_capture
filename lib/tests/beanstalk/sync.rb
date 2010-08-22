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
require 'rubygems'                      #1.8.7
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



