#!/usr/bin/env ruby

require 'thread'

class ThreadPool

  def initialize(max_size)
    @pool = []
    @threadqueue = ::Queue.new
    @resultqueue = ::Queue.new
    @max_size = max_size
    @pool_mutex = Mutex.new
    @pool_cv = ConditionVariable.new
  end

  def defer(op = nil, callback = nil, &blk)
    @threadqueue << [op||blk,callback]
  end

  def run_deferred_callbacks
    until (@resultqueue ||= []).empty?
      result,cback = @resultqueue.pop
      cback.call result if cback
    end
  end

  def dispatch()
    Thread.new do
      # Wait for space in the pool.
      @pool_mutex.synchronize do
        while @pool.size >= @max_size
#          puts "Pool is full; waiting to run #{args.join(',')}…" if $DEBUG
          # Sleep until some other thread calls @pool_cv.signal.
          @pool_cv.wait(@pool_mutex)
        end
      end

      @pool << Thread.current

      begin
        op, cback = *@theadqueue.pop
        result = op.call
        @resultqueue << [result, cback]
      rescue => e
        exception(self, e, *args)
      ensure
        @pool_mutex.synchronize do
          # Remove the thread from the pool.
          @pool.delete(Thread.current)
          # Signal the next waiting thread that there's a space in the pool.
          @pool_cv.signal
        end
      end
    end
  end

  def shutdown
    @pool_mutex.synchronize { @pool_cv.wait(@pool_mutex) until @pool.empty? }
  end

  def exception(thread, exception, *original_args)
    # Subclass this method to handle an exception within a thread.
    puts "Exception in thread #{thread}: #{exception}"
  end
end

if __FILE__ == $0
  startt = Time.now
  pool = ThreadPool.new(20)
  Signal.trap('INT')   { pool.shutdown }
  Signal.trap('TERM')  { pool.shutdown }

  20.times do |i|
    pool.dispatch(i) do |i|
      sleep(1)
      if i == 19
        $stderr.puts "Done in #{Time.now - startt} seconds"
      end
    end
  end
  sleep(3)
  pool.shutdown
end
