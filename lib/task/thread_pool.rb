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
      thread_id = 0
      until @threadpool.size == @threadpool_size.to_i
        thread = Thread.new do
          Thread.current[:name] = "pool:#{thread_id+=1}"
          while true
            op, cback = *@threadqueue.pop
            begin
              result = op.call
              @resultqueue << [result, cback]
            rescue Exception => e
              $stderr.puts "Exception in deferred call #{e}"
            end
          end
        end
        @threadpool << thread
      end
    end

    def result_count()
      @resultqueue.size
    end

    def job_count()
      @threadqueue.size
    end

    def defer op = nil, callback = nil, &blk
      @threadqueue << [op||blk,callback]
    end

    def run_deferred_callbacks
      until @resultqueue.empty?
        result,cback = @resultqueue.pop
        cback.call result if cback
      end
    end
  end
end
