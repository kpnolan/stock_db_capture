#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
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

    def members()
      @threadpool
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
