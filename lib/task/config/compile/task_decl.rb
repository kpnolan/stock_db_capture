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
require 'task/message'

module Task
  module Config
    module Compile
      class TaskDecl
        attr_reader :name, :options, :params, :targets, :inputs, :outputs, :flow
        attr_reader :result_protocol, :wrapper_name, :wrapper_proc, :body
        attr_accessor :parent

        delegate :info, :error, :debug, :flush, :to => :@@logger

        cattr_accessor :config

        def initialize(name, options, &body)
          @name = name
          @options = options
          @parent = nil
          @body = body
        end

        def process_options()
          opts = options.dup
          @targets = opts.delete(:targets) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :targets must be specified for #{name}"; nil }
          @inputs = opts.delete(:inputs) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :inputs must be specified for #{name}"; nil }
          @outputs = opts.delete(:outputs) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :outputs must be specified for #{name}"; nil }
          @flow = opts.delete(:flow) { raise Task::Config::Compile::TaskException, "a :flow option must be specified the for consumer: #{name}" unless inputs.empty?; nil }
          @wrapper_name = opts.delete(:wrapper)
          @params = opts.delete(:params)
          @result_protocol = opts.delete(:result_protocol)
          raise Task::Config::Compile::TaskException, "unknown options #{opts.inspect} declared for task " unless opts.empty?
        end

        def producer?
          parent.nil?
        end

        def consumer?
          parent != nil
        end

        def process_wrapper_name()
          method = "#{wrapper_name}_proc".to_sym
          raise raise Task::Config::Compile::TaskException, "wrapper function: #{method} do no exist, spelling error?" unless config.respond_to? method
          @wrapper_proc = config.send(method, self, params, &body)
        end
        #
        # Compile time validation. Check to make sure the next task's input sig is output the same as the output sig.
        # Note that this must take into consideration that some output types are proxies. An output proxy must be
        # dereferenced before the next task is called
        #
        def ct_validate(target)
          if outputs != target.inputs
            msg = "#{target.name}(#{target.inputs.join(', ')} does not match  #{name}(#{outputs.join(', ')})"
            raise Task::Config::Compile::TypeException, msg
          end
        end
        #
        # this is an undocumented feature of Ruby, i.e. passing a proc as a block to instance_exec which
        # somehow require self to be the first are to work. Even though self is supposed to be
        # implicitly passed to a block
        #
        def eval_body(input_object, id=nil)
          Message.job_stats.eval_thread(id, Thread.current[:name]) if id
          Message.job_stats.eval_start(id) if id
          if wrapper_proc
            Thread.current[:results] = self.instance_exec(input_object, &wrapper_proc)
            Message.job_stats.eval_complete(id) if id
            Thread.current[:results]
          else
            Thread.current[:results] = self.instance_exec(input_object, &body)
            Message.job_stats.eval_complete(id) if id
            Thread.current[:results]
          end
        end
        #
        # Nice clean uncomplicated
        #
        def decode_proxy(proxy)
          if proxy.respond_to?(:dereference)
            obj = proxy.dereference
          else
            raise  Task::Config::Runtime::TypeException, "#{proxy.class} does not support :dereference"
          end
        end
        #
        # Nice, clean, uncomplicated
        #
        def encode_proxy(orig_obj)
          return orig_obj if orig_obj.is_proxy?
          return orig_obj.to_proxy if orig_obj.respond_to? :to_proxy
          raise  Task::Config::Runtime::TypeException, "#{orig_obj.class} does not support :to_proxy"
        end

        class << self

          def lookup_task(name)
            @@config.task_hash.fetch(name) { raise Task::Config::Runtime::TypeException, "unknown Type: #{name} referenced" }
          end

          def bind_to_config(config)
            @@config = config
          end

          def attach_logger(logger)
            @@logger = logger
          end
        end
      end
    end
  end
end
