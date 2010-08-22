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
