require 'rubygems'
require 'ruby-debug'
require 'thread'

n = 5
count = 0
counts = Array.new(n) { 0 }

def mk_thread(i, pri)
 t = Thread.new(i, pri) { |i, pri|
    Thread.current.priority = pri
    Thread.stop
    loop do
      count[i] += 1
      Thread.pass
    end
  }
end

threads = (1..n).map { |i| mk_thread(i, -1) }
threads.each { |t| t.run }

for i in 0..1000
  Thread.pass
end

threads.each { |t| t.kill }

puts "main: #{i} counts: #{counts.inspect}"
