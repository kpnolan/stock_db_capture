

@count = 0
@rescnt = 0

op = proc { @count += 1 }
cb = proc { |result| @rescnt += result }

@threadpool_size = 20

def spawn_threadpool # :nodoc:
  until @threadpool.size == @threadpool_size.to_i
    thread = Thread.new do
      while true
        op, cback = *@threadqueue.pop
        result = op.call
        @resultqueue << [result, cback]
      end
    end
    @threadpool << thread
  end
end

def defer op = nil, callback = nil, &blk
  unless @threadpool
    require 'thread'
    @threadpool = []
    @threadqueue = ::Queue.new
    @resultqueue = ::Queue.new
    spawn_threadpool
  end
  @threadqueue << [op||blk,callback]
end

def run_deferred_callbacks # :nodoc:
  until (@resultqueue ||= []).empty?
    result,cback = @resultqueue.pop
    cback.call result if cback
  end
end


defer op, cb
defer op, cb
defer op, cb

#debugger

puts "runing cbacks"
run_deferred_callbacks()
puts "runing cbacks over: #{@rescnt}"
