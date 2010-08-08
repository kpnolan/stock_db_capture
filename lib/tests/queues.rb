require 'thread'

q = ::Queue.new

t = Thread.fork {
  loop do
    val = q.pop
    puts "#{Time.now} ---- #{val}"; $stdout.flush
  end
}

sleep(5)

v = 0
loop do
  sleep(3)
  puts "#{Time.now} status: #{t.status}"; $stdout.flush
  puts "#{Time.now}  writing #{v}"; $stdout.flush
  q.push(v)
  v += 1
end






