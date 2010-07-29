require 'fiber'

x = 0

def delay(item)
    fib = Fiber.current
    proc = lambda { |result| sleep(1); fib.resume(result) }
    Fiber.yield     proc.call(item)

end

value = delay(1)
puts value
puts value

#f = Fiber.new { |arg| loop { arg += 1; Fiber.yield } }



#20.times {
#  x = f.resume(x)
#  puts x.class
#}

