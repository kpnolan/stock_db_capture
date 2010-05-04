# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'ruby-debug'
require 'yaml'
require 'tsort'
require 'thread'
require 'singleton'
require 'rpctypes'
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
      #
      # A type declaration (denoted by the 'type' statement declares how one type can be converted to a target type.
      # A block is supplied which carries out the actuall conversion. All validate of type correctness is handled
      # automatically therefore it is not necessary to do any checking withing the conversion block proper. If, however,
      # the value itself needs further checking to determine valid data that must be handled in the conversion block.
      # N.B. This implements a one-to-one type conversion. Composite types are not handled. It is expected if a type
      # contains more than one builtin types, a class has been delcared to wrap the multiple values. Also, the
      # convension is that the conversion are mainly focus on encoding and decoded value references to be sent over
      # the wire and the protocol used is one of :to_proxy and :dereference
      #
      TypeDecl = Struct.new(:fqname, :key, :sig, :output, :arity, :basic_type_sig, :converter) do

        cattr_accessor :check, :config, :logger

        def initialize(fqname, options, &block)
          self.fqname = fqname
          self.key = fqname.to_s
          self.sig = options[:signature]
          self.output = fqname.is_a?(Symbol) ? sig : fqname # FIXME  what about sigs which are arrays?
          self.converter = block
          raise Task::Config::Compile::TypeException, "the arity of the conversion block must be one, i.e. Type1 to Type2" unless block.arity == 1
        end
        #
        # Convert from the signature type to the target type after validating that the input type is correct
        # Optionally validate the output type to make sure there where no error in the type conversion block
        #
        def convert(value)
          rt_validate(sig, value) unless value.is_a?(Array)
          new_value = converter.call(value)
          rt_validate(output, new_value) if check
          new_value
        end
        #
        # Runtime validation that the value matches the signature. An array for a signature represents an input type
        # can be one of the array elements with must be either a nil (all types) or a known type name
        #
        def rt_validate(sig, value)
          if sig.is_a?(Array) and not sig.any? { |type| value.is_a?(type) }
            msg = "value must be one of [ #{sig.join(',')} ], value: #{value} of type #{value.class} isn't"
            raise Task::Config::Runtime::TypeException, msg
          else
            raise Task::Config::Runtime::TypeException, "value: #{value} must be a #{sig} not a #{value.class}" unless value.is_a?(sig)
          end
        end
      end
      #
      # Recursively descend the type signature expanding composite types and returning the overall
      # length of the expanded signature
      #
      def TypeDecl.flattened_type_sig_len(type, cnt=0)
        sig = lookup_type(type)
        return sig.length unless sig.any? { |type| type.is_a?(Symbol) }
        if sig.each do |type|
            if type.is_a?(Symbol)
              return expand_type_sig(type, cnt)
            else
              cnt += 1
            end
          end
        end
      end

      def TypeDecl.lookup_type(type, use_regexp=false)
        if use_regexp
          matches = config.type_hash.keys.grep(Regexp.compile("#{type}$"))
          raise  Task::Config::Runtime::TypeException, "type match with REGEXP returned multiple hits" if matches.length > 1
          return nil if matches.empty?
          type = matches.first
        end
        config.type_hash.fetch(type.to_s) { raise Task::Config::Runtime::TypeException, "unknown Type: #{type} referenced" }
      end

      def TypeDecl.bind_to_config(config)
        self.config = config
      end

      def TypeDecl.no_runtime_check(true_false)
        self.check = ! true_false
      end

      TaskDecl = Struct.new(:name, :options, :parent, :params, :targets, :inputs, :outputs, :priority, :raw_input_length, :raw_output_length,
                            :input_signature, :result_protocol, :logger, :wrapper_name, :wrapper_proc, :body) do


        delegate :info, :error, :debug, :to => :logger

        cattr_accessor :config

        def initialize(name, options, &body)
          self.name = name
          self.options = options
          self.parent = nil
          self.body = body
          #self.raw_input_length = inputs.inject(0) { |sum, type| TypeDecl.flattened_type_sig_len(type, sum) }
          #self.raw_output_length = outputs.inject(0) { |sum, type| TypeDecl.flattened_type_sig_len(type, sum) }
        end

        def signature_length(input_output)
          valid_args = [:input, :output]
          raise ArgumentError, "arg must be :input or :output" if valid_args.include? input_output
          send(input_output).inject(0) { |sum, type| sum + type.expand_type_sig() }
        end

        def process_options()
          opts = options.dup
          self.targets = opts.delete(:targets) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :targets must be specified for #{name}"; nil }
          self.inputs = opts.delete(:inputs) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :inputs must be specified for #{name}"; nil }
          self.outputs = opts.delete(:outputs) { raise Task::Config::Compile::TaskException, "a (possibly empty) array as the value of :outputs must be specified for #{name}"; nil }
          self.wrapper_name = opts.delete(:wrapper)
          self.params = opts.delete(:params)
          self.result_protocol = opts.delete(:result_protocol)
          raise Task::Config::Compile::TaskException, "unknown options #{opts.inspect} declared for task " unless opts.empty?
          self.raw_input_length = inputs.length
          self.raw_output_length = outputs.length
        end

        def process_wrapper_name()
          method = "#{wrapper_name}_proc".to_sym
          raise raise Task::Config::Compile::TaskException, "wrapper function: #{method} do no exist, spelling error?" unless config.respond_to? method
          self.wrapper_proc = config.send(method, self, params, &body)
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

        def yield_value(value)
          raise  Task::Config::Runtime::TaskException, "yeild_result called for task not declaring that result protocol" unless result_protocol == :yield
          msg  = value.is_a?(Array) ? Message.new(self, value) : Message.new(self, [value])
          msg.deliver()
          :ignore
        end
        #
        # this is an undocumented feature of Ruby, i.e. passing a proc as a block to instance_exec which
        # somehow require self to be the first are to work. Even though self is supposed to be
        # implicitly passed to a block
        #
        def eval_body(arg_ary)
          args = [args] unless args.is_a?(Array)
          if wrapper_proc
            self.instance_exec(*arg_ary, &wrapper_proc)
          else
            self.instance_exec(*arg_ary, &body)
          end
        end

        def encode_payload(arg_ary)
          arg_ary = [arg_ary] unless arg_ary.is_a?(Array)
          pairs = proxied_output_signature.zip(arg_ary)
          encoded_args = pairs.map do |pair|
            proxy = convert_arg(*pair)
            if proxy.respond_to?(:values)
              proxy.values
            else
              proxy
            end
          end
        end

        def convert_arg(type, value)
          if type.nil?
            value
          elsif value.is_a?(type)
            value
          elsif tdecl = TypeDecl.lookup_type(type)
            tdecl.convert(value)
          else
            valpp = value.is_a?(Array) ? "[ #{value.join(', ')} ]" : value
            raise  Task::Config::Runtime::TypeException, "no Type conversion has been defined for: #{type} with value #{valpp}"
          end
        end

        def decode_payload(payload)
          raise  Task::Config::Runtime::TypeException, "mismatch in payload length. Payload length: #{payload.length}, type sig length #{raw_input_length}" unless payload.length == raw_input_length
          pairs = inputs.zip(payload)
          decoded_args = pairs.map { |pair| convert_arg(*pair) }
        end
        #
        # Because we declare unproxied input types for tasks which are dereferenced during argument conversion we need
        # the Proxy form for the typesepc given to the message tempalate. This routine does just that. It looks for a
        # Proxied for for a type and returns that for the tempate
        #
        def proxied_input_signature()
          proxied_signature(inputs)
        end

        def proxied_output_signature()
          proxied_signature(outputs)
        end

        def proxied_signature(type_ary)
          type_ary.map do |type|
            if type.is_a?(Symbol)
              nil
            elsif reg_type = TypeDecl.lookup_type("#{type}Proxy", true)
              reg_type.fqname
            else
              type
            end
          end
        end
      end

      def TaskDecl.lookup_task(name)
        config.task_hash.fetch(name) { raise Task::Config::Runtime::TypeException, "unknown Type: #{name} referenced" }
      end

      def TaskDecl.bind_to_config(config)
        self.config = config
      end

      class Dsl
        include Singleton
        extend Task::RPCTypes

        attr_reader :options, :producers, :task_hash, :type_hash, :tsort, :post_process

        def initialize()
          @options = Hash.new
          @task_hash = Hash.new
          @type_hash = Hash.new
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

        def type(name, options, &body)
          raise Task::Config::Compile::TypeException, "duplicate type name: #{name}" if type_hash.has_key? name.to_s
          type = TypeDecl.new(name, options, &body)
          self.type_hash[type.key] = type
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

        def lookup_type(name)
          type = type_hash.fetch(name) { raise Task::Config::Compile::TypeException, "{name} is not a known type" }
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

        def parent_task(task_name)
          task_hash[task_name].parent
        end

        def parent_name(task_name)
          parent_task.name
        end

        def next_tasks(task)
          task.targets.map { |name| task_hash[name] }
        end

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
            TypeDecl.bind_to_config(config)
            config.instance_eval(File.read(path), path, 1)      # Effectively the first passs
            config.second_pass()
            config
          end
        end
      end
    end
  end
end
