require 'rubygems'                                             #1.8.7
require 'ostruct'
require 'message'

module Task
  class Producer
    attr_reader :task, :connection_pool, :opts, :stats
    def initialize(task, connection_pool, thread_pool, opts={})
      @opts = opts
      @task = task
      @connection_pool = connection_pool
      @stats = OpenStruct.new(:results_len => 0, :recv => 0, :deferred => 0)
    end

    def send(results)
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
      results = task.eval_body(nil)
      send(results)
    end
  end
end
