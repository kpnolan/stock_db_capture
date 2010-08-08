require 'rubygems'                                             #1.8.7
require 'ostruct'
require 'thread'
require 'message'
require 'active_support'

module Task
  class Consumer
    attr_reader :task, :connection_pool, :jobq,:t, :opts, :stats, :cb, :ichannel
    def initialize(task, connection_pool, jobq, opts={})
      @opts = opts.reverse_merge :timeout => 600
      @task = task
      @connection_pool = connection_pool
      @jobq = jobq
      @t = nil
      @ichannel = connection_pool.take(task.name)
      @stats = OpenStruct.new(:results_len => 0, :recv => 0, :deferred => 0)
      @cb = callback(self, :completer)
    end

    def callback(object = nil, method = nil, &blk)
      if object && method
        lambda { |*args| object.send method, *args }
      else
        if object.respond_to? :call
          object
        else
          blk || raise(ArgumentError)
        end
      end
    end

    def adjust_deferred_jobs(amt)
      stats.deferred += amt
    end

    def queue_job(body)
      jobq.push([ proc { task.eval_body(body) }, cb ])
    end

    def completer(results)
      adjust_deferred_jobs(-1)
      unless task.targets.empty?
        if results.respond_to?(:each) && results.length > 0
          stats.results_len += results.length
          results.each do |result|
            outgoing_msg = Message.new(task, result)
            outgoing_msg.deliver(connection_pool)
          end
        elsif not results.is_a? Enumerable
          stats.results_len += 1
          outgoing_msg = Message.new(task, results)
          outgoing_msg.deliver(connection_pool)
        end
      end
    end

    def start()
      @t = Thread.fork(task.name) { |name|
        Thread.current[:name] = name
        while job = ichannel.reserve(opts[:timeout])
          msg = Message.receive(task, job.body)
          job.delete
          stats.recv += 1
          adjust_deferred_jobs(1)
          queue_job(msg.restored_obj)
          #break if task.flow == [1,:n]
        end
      }
    end
  end
end
