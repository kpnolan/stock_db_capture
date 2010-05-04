require 'rubygems'
require 'daemons'
require 'rinda/ring'
require 'monitor'
require 'rpctypes'
require 'remote_logger'
require 'task/message'
require 'task/config/compile/dsl'
require 'task/config/compile/exceptions'
#
# Somec monkey patching on the Hash class that is too specialized to really go into here
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
    attr_accessor :proc_id

    #--------------------------------------------------------------------------------------------------------------------
    # The constructor for a daemon class. Since the worker daemons are forked, they get a copy of the process start which
    # of course includes the state stored here. The serve() method actually invokes a separate process.
    #--------------------------------------------------------------------------------------------------------------------
    def initialize(config_file, proc_id)
      @config_basename = File.basename(config_file)
      @config = Dsl.load(config_file)
      @proc_id = proc_id
      @options = config.options.reverse_merge :verbose => false, :logger_type => :remote, :message_timeout => 10
      #create readers for each of the above options
      self.extend self.options.to_mod

      DRb.start_service
      begin
        ring_server = Rinda::RingFinger.primary
        ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
        fabric = Rinda::TupleSpaceProxy.new ts
        Message.bind_to_message_fabric(fabric)
        Message.bind_to_config(config)
        Message.default_timeout = options[:message_timeout]
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
    # Set up an appropriate logger destination. If verbose is true we just log to $stderr, otherwise we log to a file
    # containing the proc_id (0..number of procs). Finally if were running as a daemon we bind to the Drb Service
    # that all daeomons write to.
    #
    def initialize_logger()
      if verbose
        @logger = ActiveSupport::BufferedLogger.new($stderr)
        @logger.auto_flushing = true
      elsif logger_type == :local
        log_path = File.join(RAILS_ROOT, 'log', "#{config_basename}.log")
        system("cat /dev/null > #{log_path}")
        @logger = ActiveSupport::BufferedLogger.new(log_path)
      else
        @logger = RemoteLogger.new(config_basename, File.join(RAILS_ROOT, 'log'), proc_id)
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
    def serve(*use_tasks)
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
      info "Number of tasks: #{tasks.length}"
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
            # wait for a message that will never come, instead we start them immediately. Only one process, however, should
            # generate activate the producer since threre is no interprocess mutex allocated.
            # N.B. This logic depends on the config file containing the producer task does a Thread.terminate
            # after yielding the producer messages. TODO this should be changed so that no thread knowlege is necessary
            # in the config files since it breaks encapsulation. However, somehow we need to know when a producer is done.
            # Perhaps this can be done with a special return value.
            #
            if task.parent.nil? && proc_id.zero?
              info("Producer invoked", task.name)
              results = task.eval_body([])
            else
              #t = Time.now
              #info "#{task.name} calling recieve at #{t.strftime('%M:%S')}:#{t.usec}"
              msg = Message.receive(task)
              #t = Time.now
              #info "#{task.name} got message at #{t.strftime('%M:%S')}:#{t.usec}"
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
            error("(#{task.name}) Rinda Timeout: #{e}", task.name)
            endt = Time.now
            delta = endt - startt
            info "#{count} message processed -- elapsed time: #{Base.format_et(delta)}", task.name
            Thread.current.terminate
          rescue Task::Config::Runtime::TypeException => e
            logger.error("#{e.class}: #{e.message}", task.name)
          rescue Task::Config::Runtime::TaskException => e
            logger.error("#{e.class}: #{e.message}", task.name)
          rescue Task::Config::Runtime::WrapperException => e
            logger.error("#{e.class}: #{e.message}", task.name)
          rescue TimeseriesException => e
            logger.error("#{e.class}: #{e.message}", task.name)
          rescue IOError => e
            logger.error("#{e.class}: #{e.message}", task.name)
            logger.error(e.backtrace.join("\n"), task.name)
          rescue ArgumentError => e
            logger.error("#{e.class}: #{e.message}", task.name)
          rescue Exception => e
            logger.error("#{e.class}: #{e.message}", task.name)
            logger.error(e.backtrace.join("\n"), task.name)
          end
        end
      end
    end

    def Base.run(config_path, proc_id)
      #
      # TODO we might want to go through the hassle of creating ApplicationOjbects and ApplicationsGroups (which have one 7monitor)
      #
      server = Base.new(config_path, proc_id)
      server.serve()
#      server.serve(:rsi_rvi_50)
#      server.serve(:scan_gen,:timeseries_args, :rsi_trigger_14)
#        server.serve(i, [:scan_gen])
#        server.serve(i, [:timeseries_args])
#        server.serve(i, [:rsi_trigger_14])
#        server.serve(i, [:rsi_rvi_50])
#        server.serve(:lagged_rsi_difference)
#        end
#     end
      summary_str = ResultAnalysis.memoized_thresholds
      server.info summary_str
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
