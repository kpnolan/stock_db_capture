require 'beanstalk-client'

beanstalk = Beanstalk::Pool.new ['127.0.0.1:11300']
loop do
  job = beanstalk.reserve
  $stderr.puts "#{job.id}: #{job.body}"
  $stderr.flush
  job.delete
end



