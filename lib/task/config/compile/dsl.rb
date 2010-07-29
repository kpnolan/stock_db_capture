# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'yaml'
require 'tsort'
require 'thread'
require 'singleton'
require 'rpctypes'
require 'task/config/compile/task_decl'
require 'task/config/compile/exceptions'

class Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(task, &block)
    fetch(task).each(&block)
  end

  def to_mod
    hash = self
    Module.new do
      hash.each_pair do |key, value|
        define_method key do
          value
        end
      end
    end
  end
end

module Task
  module Config
    module Compile
      class Dsl
        include Singleton
        extend Task::RPCTypes

        attr_reader :options, :producers, :task_hash, :type_hash, :tsort, :post_process

        def initialize()
          @options = Hash.new
          @task_hash = Hash.new
          @tsort = nil
          @producers = []
          @post_process = nil
        end

        public # DSL statements
        #
        # These four methods represent the actual statements in the DSL.
        # TODO move these methods to a module. Hopefully we still have access to the namespace w/in the outer module (like TaskDecl and TypeDecl)
        #
        def task(name, options, &body)
          raise Task::Config::Compile::TaskException, "duplicate task name: #{name}" if task_hash.has_key? name
          task = TaskDecl.new(name, options, &body)
          task_hash[name] = task
          task.process_options()
        end

        def global_options(options)
          @options = options.reverse_merge :resolution => 1.day, :price => :close, :log_flags => :basic,
          :pre_buffer => 0, :post_buffer => 0, :repopulate => true, :max_date => (Date.today-1),
          :record_indicators => false, :debug => false
          #create readers for each of the above options
          self.extend self.options.to_mod
        end

        def post_process(&block)
          @post_process = block
        end

        public # Utility Methods

        def lookup_task(name)
          task = task_hash.fetch(name) { raise Task::Config::Compile::TaskException, "{name} is not a known task" }
        end
        #
        # The second pass hooks up parent-child references an then checks to make sure that the input and output signatures
        # are the same
        #
        def second_pass()
          @tsort = form_graph_and_tsort()
          tsort.each do |task_name|
            task = task_hash[task_name]
            task.process_wrapper_name() if task.wrapper_name
            add_producer(task) if task.inputs.empty?
            task.targets.each do |child_name|
              task_hash[child_name].parent = task
              task.ct_validate(task_hash[child_name])
            end
          end
          self
        end

        def parent_task(task_name); task_hash[task_name].parent; end
        def parent_name(task_name); parent_task.name; end
        def next_tasks(task); task.targets.map { |name| task_hash[name] }; end

        def form_graph_and_tsort()
          graph = {}
          task_hash.each_pair do |name,task|
            graph[name] = task.targets
          end
          @tsort = graph.tsort.reverse
        end

        def add_producer(task)
          @producers << task
        end

        def confirmation_proc(task, params, &block)
          raise Task::Config::Rintime::TaskExcpetion, "confirmation tasks must include a :window param for #{task.name}" if params[:window].nil?
          raise Task::Config::Runtime::TaskException, ":start_date not specified for task #{task.name}"  if params[:start_date].nil?
          sdate_method = params[:start_date]
          time_span = params[:window]
          resolution = resolution()
          lambda do |position|
            start_date = position.send(sdate_method)
            max_exit_date = Position.trading_date_from(start_date, time_span)
            if max_exit_date > Date.today-1
              ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
              max_exit_date = ticker_max.localtime
            end
            begin
              ts = Timeseries.new(position.ticker_id, start_date..end_date, resolution, :logger => task.logger)
              confirming_index = ts.instance_exec(params, position, &block)
              if confirming_index.nil?
                position.destroy
                raise Task::Config::Runtime::WrapperExcpetion, "Confirmation returning nil (position deleted)"
              end
            rescue TimeseriesException => e
              position.destroy
              raise
            end
            confirming_index
          end
        end

        def displacement_proc(task, params, &block)
          raise Task::Config::Runtime::TaskExcpetion, "displacement tasks must include a :window param for #{task.name}" if params[:window].nil?
          raise Task::Config::Runtime::TaskException, ":start_date not specified  for #{task.name}"  if params[:start_date].nil?
          sdate_method = params[:start_date]
          time_span = params[:window]
          resolution = resolution()
          lambda do |position|
            begin
              start_date = position.send(sdate_method)
              max_exit_date = Position.trading_date_from(start_date, time_span)
              if max_exit_date > Date.today-1
                ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
                max_exit_date = ticker_max.localtime
              end
              #puts "calling timeseries with #{position.ticker.symbol} #{start_date}..#{max_exit_date}"
              ts = Timeseries.new(position.ticker_id, start_date..max_exit_date, resolution, :logger => task.logger)

              result = ts.instance_exec(params, position, &block)
              #puts "ts result: #{result.join(', ')}"
              result
            rescue TimeseriesException => e
              position.destroy
              raise
            rescue ActiveRecord::StatementInvalid
              position.destroy
              raise
            end
          end
        end

        class << self

          def load(cfg_file)
            unless cfg_file[0] == '/'
              path = File.join(RAILS_ROOT, 'lib', 'task', 'config', 'config_files', cfg_file+'.cfg')
            else
              path = cfg_file
            end
            config = Dsl.instance()
            TaskDecl.bind_to_config(config)
            config.instance_eval(File.read(path), path, 1)      # Effectively the first passs
            config.second_pass()
            config
          end
        end
      end
    end
  end
end
