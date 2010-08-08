require 'beanstalk-client'

beanstalk = Beanstalk::Pool.new ['127.0.0.1:11300']
id1 = beanstalk.put('hello1')
id2 = beanstalk.put('hello2')
$stderr.puts "put id #{id1}"
$stderr.puts "put id #{id2}"
$stderr.flush

