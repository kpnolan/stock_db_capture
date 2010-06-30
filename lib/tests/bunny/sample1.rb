require 'bunny'

my_client = Bunny.new(:logging => true)
begin
  puts 'before start'
  my_client.start
  puts 'after start'
  my_q = my_client.queue('my_queue')
rescue Exception => e
  puts e
  exit
end

begin
  ret = my_q.subscribe(:timeout => 5) { |msg| puts msg }
  if ret == :timed_out
    puts "timed out!"
    my_q.unsubscribe
  end
  puts ret.inspect
rescue Exception => e
  puts e
end


