require 'rubygems'
require 'daemons'
require 'rinda/ring'
require 'monitor'
require 'rpctypes'
require 'task/message'
require 'task/remote_logger'
require 'task/config/compile/dsl'
require 'task/config/compile/exceptions'

#
# Some monkey patching on the Hash class that is too specialized to really go into here
#
class Hash
  include TSort
  alias tsort_each_node each_key
  def tsort_each_child(node, &block)
    fetch(node).each(&block)
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


#--------------------------------------------------------------------------------------------------------------------
# A Task::Base is represents a container within which a number of tasks are started each on it's own thread . The Base
# container is generally a daemon although it can be configured to uun on top of the shell.
# Tasks usuall are both consumers and producers. The model of a task is
# that is runs on it's own thread and waits for messages directed it before acting upon it. A task has a Proc associated
# with it which get's executed once the input payload sent with the message has been decoded. It the task fires the Proc,
# passing in the decoded payload args. In the usual case the Proc returns set of values when are then encoded into the
# message to be delivered to all of its target tasks (which may be more than one in a fannot) or more likely just the
# following task. All of the payload transscoding is done automatically and may generate error of the wrong types or no.
# of args is returned. It is possible for a task to execute a loop in wich mutiple messages are sprayed out before the
# thread goes back to waiting.
#--------------------------------------------------------------------------------------------------------------------
module Task
  class Base
    extend Task
    include Task::Config::Compile

    delegate :info, :error, :debug, :to => :logger

    attr_reader :options, :post_process
    attr_reader :config_basename, :config, :fabric
    attr_reader :threads, :logger
    attr_accessor :proc_id, :daemon_opts

    #--------------------------------------------------------------------------------------------------------------------
    # The constructor for a daemon class. Since the worker daemons are forked, they get a copy of the process start which
    # of course includes the state stored here. The serve() method actually invokes a separate process.
    #--------------------------------------------------------------------------------------------------------------------
    def initialize(config_file, daemon_opts={})
      @config_basename = File.basename(config_file)
      @config = Dsl.load(config_file)
      @options = config.options.reverse_merge :verbose => true
      @daemon_opts = daemon_opts
      #create readers for each of the above options
      self.extend self.options.to_mod

      DRb.start_service
      begin
        ring_server = Rinda::RingFinger.primary
        ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
        fabric = Rinda::TupleSpaceProxy.new ts
        Message.bind_to_message_fabric(fabric)
        Message.bind_to_config(config)
        Message.default_timeout = 10
      rescue Exception => e
        $stderr.puts "Cannot find Rinda Ringserver: please run 'sudo ringserver start' to correct this problem -- aborting"
        raise
      end

      initialize_logger()
      Message.attach_logger(logger)

      @threads = []
      @threads.extend(MonitorMixin)
      Thread.abort_on_exception = false
    end

    #
    # Is that running as a daemon or on top of he shell?
    #
    def on_top?
      daemon_opts[:ontop]
    end
    #
    # Set up an appropriate logger destination. If verbose is true we just log to $stderr, otherwise we log to a file
    # containing the proc_id (0..number of procs). Finally if were running as a daemon we bind to the Drb Service
    # that all daeomons write to.
    #
    def initialize_logger()
      if on_top?
        if verbose
          @logger = ActiveSupport::BufferedLogger.new($stderr)
          @logger.auto_flushing = true
        else
          log_path = File.join(RAILS_ROOT, 'log', "#{config_basename}_#{proc_id}.log")
          system("cat /dev/null > #{log_path}")
          @logger = ActiveSupport::BufferedLogger.new(log_path)
        end
      else
        @logger = RemoteLogger.new(proc_id)
      end
    end

    #--------------------------------------------------------------------------------------------------------------------
    # The serve function is called as the entry point for any number of worker tasks, each responding to messages and
    # sending out messages along with the results of the given task. Retrun values from one task become the input args
    # of one or more target tasks. Any type conversion need to map output args to input args is done automatically.
    # Since Ruby objects are stored on the heap but the messages and payloads are stored in a NUMA, proxy classes are
    # often generated to inplement a pass-by-reference protocol. Upon reciept of payloads with Proxy objects they are
    # automatically derefernced into a Heap local object.
    #--------------------------------------------------------------------------------------------------------------------
    def serve(proc_id, use_tasks=[])
      @proc_id = proc_id

      startt = global_startt = Time.now
      #
      # Create a list of tasks taken from the topoligically sorted chain of tasks, start with the initial task
      # and ending with the terminal task
      #
      if use_tasks.empty?
        tasks = config.tsort.map { |name| config.lookup_task(name) }
      else
        tasks = config.tsort.map { |name| use_tasks.include?(name) ? config.lookup_task(name) : nil }
        tasks.compact!
      end
      info "Number of task: #{tasks.length}"
      #
      # Create a thread for each task in the config file. The semantics of that thread
      # is contained in the task objects runtime Proc (which is built by reading the config file)
      tasks.each_with_index { |task, idx| task_thread(task, idx) }
      #
      # Wait until all the threads timeout with either means that there is nothing left to do or some unrecoverable
      # error was encounted
      #
      threads.each { |thread| thread.join }
      endt = Time.now
      delta = endt - startt
      info "#{options[:app_name]} total elapsed time #{Base.format_et(delta)}"
    end
    #
    # A Thread is dedicated to each named block in the configuration file. The threads just wait until
    # a message shows up with their "name" on it, extra the relavent runtime information and the
    # call the block of Ruby code associated with that message.  A node has a type with loose describes
    # is symantas although the actuall clode is a function of the template specified for that
    # node and the code proper given with the node delarations. Resutls of blocks are treated like
    # messages, i.e. a code block waits for the result to show up before the code block
    # and proceed anty further.
    # TODO rewrite comment
    def task_thread(task, idx)
      task.logger = logger
      Thread.new(task, idx) do |task, idx|
        threads.synchronize { threads.push(Thread.current) }
        count = 0
        startt = Time.now
        loop do
          begin
            #
            # Those task that have no parent are producers only there they don't get trigger by a message, therefore we don't
            # wait for a message that will never come, instead we start them immediately
            #
            if task.parent.nil?
              #info("Producer #{task.name} invoked")
              results = task.eval_body([])
            else
              info "in main loop waiting for #{task.name}" if verbose
              msg = Message.receive(task)
              info("received (#{proc_id}:#{count}) #{task.name}(#{msg.task_args.inspect})") if verbose
              results = task.eval_body(msg.task_args)
            end
            #
            # If a task is one the tail (no depenencies) their are no results to propagate. Similarly tasks with yield there results
            # do so on their own. We don't bother with processing the results at all
            #
            unless task.targets.empty? || task.result_protocol == :yield
              outgoing_msg = Message.new(task, results)
              outgoing_msg.deliver()
            end
            count += 1
          rescue Rinda::RequestExpiredError => e
            error("Rinda Timeout: #{e}")
            endt = Time.now
            delta = endt - startt
            info "(#{proc_id}): #{task.name} #{count} positions processed -- elapsed time: #{Base.format_et(delta)}"
            Thread.current.terminate
          rescue Task::Config::Runtime::TypeException => e
            logger.error("#{e.class}: #{e.message}")
          rescue Task::Config::Runtime::TaskException => e
            logger.error("#{e.class}: #{e.message}")
          rescue Task::Config::Runtime::WrapperException => e
            logger.error("#{e.class}: #{e.message}")
          rescue TimeseriesException => e
            logger.error("#{e.class}: #{e.message}")
          rescue ArgumentError => e
            logger.error("#{e.class}: #{e.message}")
          rescue Exception => e
            logger.error("#{e.class}: #{e.message}")
          end
        end
      end
    end

    def Base.run(config_path, daemon_count)
      options = {
        :dir_mode => :normal,
        :dir => File.join(RAILS_ROOT, 'log'),
        :multiple => true,
        :log_output => true,
        :baacktrace => true,
        :ontop => true
      }
      #
      # TODO we might want to go through the hassle of creating ApplicationOjbects and ApplicationsGroups (which have one monitor)
      #
      task_names =  [:scan_gen, :timeseries_args, :rsi_trigger_14, :open_rsi_rvi,
                     :exit_rsirvi, :rsi_rvi_50, :lagged_rsi_difference, :rsirvi_close ]
      task_groups = []
      task_names.in_groups(daemon_count) { |group| task_groups << group }
      daemon_count.times do |i|
        Daemons.run_proc('task_manager', options) do
          daemon_options = Daemons.controller ?  Daemons.controller.options : { :ontop => true }
          server = Base.new(config_path, daemon_options)
          server.serve(i, task_groups[i])
#        server.serve(i, [:scan_gen])
#        server.serve(i, [:timeseries_args])
#        server.serve(i, [:rsi_trigger_14])
#        server.serve(i, [:open_rsi_rvi])
#        server.serve(i, [:rsi_rvi_50])
#        server.serve(i, [:exit_rsirvi])
#        server.serve(i, [:lagged_rsi_difference])
#        server.serve(i, [:rsirvi_close])
        end
      end
    end

    #--------------------------------------------------------------------------------------------------------------------
    # format elasped time values. Does some pretty printing about delegating part of the base unit (seconds) into minutes.
    # Future revs where we backtest an entire decade we will, no doubt include hours as part of the time base
    #--------------------------------------------------------------------------------------------------------------------
    def Base.format_et(seconds)
      if seconds > 60.0 and seconds < 120.0
        format('%d minute and %d seconds', (seconds/60).floor, seconds.to_i % 60)
      elsif seconds > 120.0
        format('%d minutes and %d seconds', (seconds/60).floor, seconds.to_i % 60)
      else
        format('%2.2f seconds', seconds)
      end
    end
  end
end

