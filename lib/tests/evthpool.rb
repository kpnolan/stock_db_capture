require 'thread'

module Task
  class ThreadPool

    THREAD_POOL_SIZE = 20

    def initialize(size=THREAD_POOL_SIZE)
      @threadpool_size = size
      @threadpool = []
      @threadqueue = ::Queue.new
      @resultqueue = ::Queue.new
      spawn_threadpool()
    end

    def spawn_threadpool
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
      @threadqueue << [op||blk,callback]
    end

    def run_deferred_callbacks # :nodoc:
      until (@resultqueue ||= []).empty?
        result,cback = @resultqueue.pop
        cback.call result if cback
      end
    end
  end
end

