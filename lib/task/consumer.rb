require 'rubygems'                                             #1.8.7
require 'ostruct'
require 'thread'
require 'message'
require 'active_support'

module Task
  class Consumer
    attr_reader :task, :connection_pool, :jobq,:thread, :opts, :stats, :ichannel
    def initialize(task, connection_pool, jobq, opts={})
      @task = task
      @connection_pool = connection_pool
      @jobq = jobq
      @thread = nil
      @ichannel = connection_pool.take(task.name)
      @stats = OpenStruct.new(:results_len => 0, :recv => 0, :deferred => 0)
    end

    def callback(object = nil, method = nil, id = nil, &blk)
      if object && method && id
        lambda { |*args| object.send method, id, *args }
      elsif object && method
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

    def queue_job(id, body)
      jobq.push([ proc { task.eval_body(body, id) }, callback(self, :completer, id) ])
    end

    def completer(id, results)
      adjust_deferred_jobs(-1)
      Message.job_stats.completed(id)
      unless task.targets.empty?
        if results.respond_to?(:each) && results.length > 0
          #$stderr.puts "#{task.name}: completing job #{id} results: #{results.inspect}"
          stats.results_len += results.length
          results.each do |result|
            outgoing_msg = Message.new(task, result)
            outgoing_msg.deliver(connection_pool)
          end
        elsif not results.is_a? Enumerable
          stats.results_len += 1
          #$stderr.puts "#{task.name}: completing job #{id} result: #{results.inspect}"
          outgoing_msg = Message.new(task, results)
          outgoing_msg.deliver(connection_pool)
        end
      end
    end

    def start()
      @thread = Thread.fork(task.name) { |name|
        Thread.current[:name] = name
        ichannel.sync_each do |job|
          $stderr.puts "#{task.name}: in sync block job #{job.id}" if task.name == :task4
          msg = Message.receive(task, job)
          $stderr.puts "#{task.name}: after Msg.receive job #{job.id}" if task.name == :task4
          stats.recv += 1
          adjust_deferred_jobs(1)
          queue_job(msg.id, msg.restored_obj)
          $stderr.puts "#{task.name}: after queue job #{job.id}" if task.name == :task4
#          break if task.flow == [1,:n]
        end
      }
    end
  end
end
