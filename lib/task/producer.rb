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
      results = task.eval_body(nil, nil)
      send(results)
    end
  end
end
