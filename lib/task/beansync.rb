require 'rubygems'                                  #1.8.7
require 'daemons'
require 'beanstalk-client'
require 'remote_logger'
require 'task/rpctypes'
require 'task/thread_pool'
require 'task/message'
require 'task/consumer'
require 'task/producer'
require 'task/connection_pool'
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
#
# More monkey patches
#
module ActiveSupport
  class BufferedLogger
    alias_method :raw, :info
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
    POOL_SIZE = 5
    DEFAULT_PORT = 11300
    DEFAULT_ADDR = '127.0.0.1'
    THREAD_POOL_SIZE = 20

    include Task::Config::Compile
    include Beanstalk
    extend Beanstalk

    delegate :info, :error, :debug, :flush, :to => :logger

    attr_reader :options, :post_process
    attr_reader :config_basename, :config, :csettings
    attr_reader :con_pool, :ip_addrs, :thpool, :ptasks, :ctasks, :consumers, :producers, :jobq, :startt, :global_startt, :complete
    attr_reader :logger
    attr_accessor :proc_id, :proc_count, :loop_counter, :deferred_jobs, :completed_defers, :prev_counts

    #--------------------------------------------------------------------------------------------------------------------
    # The constructor for a daemon class. Since the worker daemons are forked, they get a copy of the process start which
    # of course includes the state stored here. The serve() method actually invokes a separate process.
    #--------------------------------------------------------------------------------------------------------------------
    def initialize(config_file, proc_id, proc_count)
      @config_basename = File.basename(config_file)
      @config = Dsl.load(config_file)
      @proc_id = proc_id
      @thpool = ThreadPool.new(THREAD_POOL_SIZE)
      @deferred_jobs = 0
      @completed_defers = 0
      @loop_counter = 0
      @jobq = ::Queue.new
      @proc_count = proc_count
      @ip_addrs = nil
      @complete = false
      @@con_pool = @con_pool = nil
      @@server = self
      @options = config.options.reverse_merge :verbose => false
      raise ArgumentError, "config file does not have a required global csettings options" unless options.has_key?(:csettings)
      #create readers for each of the above options
      self.extend self.options.to_mod

      @@logger = @logger = initialize_logger()

      Thread.current[:name] = 'main'

      Message.bind_config(config)
      Message.attach_logger(logger)
#      Timeseries.attach_logger(logger)
      Thread.abort_on_exception = false
    end
    #
    # Set up an appropriate logger destination. If verbose is true we just log to $stderr, otherwise we log to a file
    # containing the proc_id (0..number of procs). Finally if were running as a daemon we bind to the Drb Service
    # that all daeomons write to.
    #
    def initialize_logger()
      case logger_type
      when :local
        log_path = File.join(RAILS_ROOT, 'log', "#{config_basename}.log")
        system("cat /dev/null > #{log_path}")
        ActiveSupport::BufferedLogger.new(log_path)
      when :remote
        RemoteLogger.new(config_basename, File.join(RAILS_ROOT, 'log'), proc_id)
      when :stderr
        logger = ActiveSupport::BufferedLogger.new($stderr)
        logger.auto_flushing = true
        logger
      else
        raise ArgumentError, "logger_type must be :local,:remote or :stderr"
      end
    end
    #
    #--------------------------------------------------------------------------------------------------------------------
    # The serve function is called as the entry point for any number of worker tasks, each responding to messages and
    # sending out messages along with the results of the given task. Retrun values from one task become the input args
    # of one or more target tasks. Any type conversion need to map output args to input args is done automatically.
    # Since Ruby objects are stored on the heap but the messages and payloads are stored in a NUMA, proxy classes are
    # often generated to inplement a pass-by-reference protocol. Upon reciept of payloads with Proxy objects they are
    # automatically derefernced into a Heap local object.
    #--------------------------------------------------------------------------------------------------------------------
    def serve(*use_tasks)
      Thread.current[:name] = 'main'
      begin
        @startt = @global_startt = Time.now
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

        Task::Config::Compile::TaskDecl.attach_logger(logger)

        logger.info "Number of tasks: #{tasks.length}"

        #
        # Extract producers and consumers from task topoloty
        #
        @ptasks = tasks.select { |task| task.producer? && proc_id == proc_count - 1  }
        @ctasks = tasks.select { |task| task.consumer? }
        #
        # Set up the connection pool
        #
        @@con_pool = @con_pool = ConnectionPool.new(ctasks.map(&:name), 1, csettings)
        #
        # Set up the main Producer and Consumer objects
        #
        @consumers = @ctasks.map { |task| Consumer.new(task, con_pool, jobq) }
        @producers = @ptasks.map { |task| Producer.new(task, con_pool, thpool) }
        #
        # Invoke the producers
        #
        producers.each { |p| p.start }
        #
        # Fire up the consumers
        #
        consumers.each { |c| c.start }
        #
        # Print statistics every 10 secs
        #
        print_reocurring_status()
        #
        # Main loop
        #
        logger.info "Entering Main Loop"; flush()
        loop {
          thpool.run_deferred_callbacks()
          thpool.defer(*jobq.pop) until jobq.empty?
          break if complete
          sleep(0.001)
        }
        finish()
        #
        # And that's all folks...
        #
      rescue => e
        error "#{e.class}: #{e.message}"
        error e.backtrace.join("\n")
        raise
      end
    end
    #
    # Print Statistics every 10 seconds
    #
    def print_reocurring_status(interval=10)
      @stats_thread = Thread.fork(0) { |tcount|
        Thread.current[:name] = 'stats'
        loop do
          sleep(interval)
          begin
            total_defers = 0
            lines = []
            sent_to = Message.to_task_count.dup
            consumers.each do |c|
              name = c.task.name
              defers = c.stats.deferred
              recv = c.stats.recv
              rcnt = c.stats.results_len
              sent = sent_to.include?(name) ? sent_to[name] : 0
              total_defers += defers
              lines << format('[%1d:%2d]%22s  Defers: %5d Messages sent:recv %5d:%5d:%d', proc_id, tcount, name, defers,sent,recv,rcnt)
            end
            sent = Message.sent_messages
            recv = Message.received_messages
            lines << format("[%1d:%2d] %37sMessages sent:recv %5d:%5d   Jobs:Queued:Results %5d:%5d:%5d\n",
                            proc_id, tcount, ' ',sent, recv, jobq.size, thpool.job_count, thpool.result_count)
            logger.raw(lines.join("\n"))
          rescue Exception => e
            $stderr.puts e.to_s
            $stderr.puts e.backtrace.join("\n")
          end

          #@complete = true unless activity?(jobq.size, thpool.job_count, thpool.result_count)
          tcount += 1
        end
      }
    end
    #
    # Wait until all the threads timeout with either means that there is nothing left to do or some unrecoverable
    # error was encounted
    #
    def activity?(*qcounts)
      qcounts.any? { |cnt| cnt > 0 } or consumers.any? { |c| c.thread.status == 'run' } or thpool.members.any? { |t| t.status == 'run' }
    end

    def generaate_socket_addrs(ipaddr=DEFAUL_ADDR, port=DEFAULT_PORT, count=POOL_SIZE)
      addr_ary = []
      count.times { addr_ary << "#{ipaddr}:#{port}" }
      addr_ary
    end

    def finish()
      logger.raw("No message activity...initiating stop\n")
      print_internal_stats(true)
      endt = Time.now
      delta = endt - startt
      info "#{options[:app_name]} total elapsed time #{Base.format_et(delta)}"; logger.flush
      con_pool.shutdown()
      logger.close()
      exit()
    end
    #
    # Dump as much internal status as possible
    #
    def print_internal_stats(final=false)
      #
      # Find and print any incompleted jobs
      #
      if final
        task_groups = Message.job_stats.incomplete_jobs.group_by { |jt| jt.message.task.name }
        task_groups.reject! { |k, v| config.lookup_task(k).producer? }   # We don't track producers
        avg_defer_times = { }
        task_groups.each_pair do |k,v|
          logger.raw "#{k}: incompleted jobs (#{v.length}):"
          v.each do |jt|
            body = jt.message.opaque_obj.dereference
            str = format("[%1d:%5d] Sent -- Recevied %s - %s Eval Started -- Completed %s -- %s Thread: %s Msg Body: %s\n",
                         proc_id, jt.id, jt.fmt(:sent_at), jt.fmt(:received_at), jt.fmt(:eval_started_at), jt.fmt(:eval_completed_at), jt.last_thread, body.to_s)
            logger.raw(str)
          end
        end
      end
      #
      # Compute Average Defer Time by Task
      #
      logger.raw("Average defer times by task\n\n")
      avg_defer_times = Message.job_stats.average_defer_times
      lines = avg_defer_times.map { |k,v| format("%24s: %3.2f", k, v) }
      logger.raw(lines.join("\n"))
      #
      # General global stats
      #
      sent = Message.sent_messages
      recv = Message.received_messages
      line = format("Messages sent:recv %5d:%5d   Jobs:Queued:Results %5d:%5d:%5d\n",
                    sent, recv, jobq.size, thpool.job_count, thpool.result_count)
      logger.raw(line)
      #
      # Thread Pool
      #
      logger.raw("Thead Stats\n")
      logger.raw("  Thread Pool\n")
      lines = thpool.members.map { |th| "    #{th[:name]}: \t #{th.status}" }
      logger.raw(lines.join("\n"))
      #
      # Consumer threads
      #
      logger.raw("  Consumer Threads\n")
      lines = consumers.map { |c| th = c.thread; "    #{th[:name]}: \t #{th.status}" }
      logger.raw(lines.join("\n"))
      #
      # Test for activity
      #
      activity = activity?(jobq.size, thpool.job_count, thpool.result_count)
      logger.raw("\nactivity? reports #{activity ? 'SOME' : 'NO'} activity\n")
    end

    class << self

      def run(config_path, server_count)
        env_check()
        #
        # TODO we might want to go through the hassle of creating ApplicationOjbects and ApplicationsGroups (which have one 7monitor)
        #
        child_count = server_count - 1
        child_count.times do |child_index|
          Process.fork do
            ActiveRecord::Base.connection.reconnect!
            exec(config_path, child_index, child_count)
          end
        end
        if child_count > 0
          p Process.waitall
        else
          Signal.trap('INT') { @@con_pool.shutdown(); @@logger.close; exit }
          Signal.trap('TERM'){ @@con_pool.shutdown(); @@logger.close; exit }
          Signal.trap('HUP') { @@server.print_internal_stats() }
          exec(config_path, 0, 1)
        end
      end

      def exec(config_path, child_index, child_count)
        $sever = server = Base.new(config_path, child_index, child_count)
        server.serve()
        #server.serve(:starter, :scan_gen ,:timeseries_args, :rsi_trigger_14)
        #      server.serve(:rsi_rvi_50)
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
      #  Verifies that the preconditions to a successful run are met, print an error msg and exit with a bad status if not
      #--------------------------------------------------------------------------------------------------------------------
      def env_check
        unless Position.count.zero?
          $stderr.puts "Position table is not empty! (needs to be truncated first)"
          exit(5)
        end
      end
      #--------------------------------------------------------------------------------------------------------------------
      # format elasped time values. Does some pretty printing about delegating part of the base unit (seconds) into minutes.
      # Future revs where we backtest an entire decade we will, no doubt include hours as part of the time base
      #--------------------------------------------------------------------------------------------------------------------
      def format_et(seconds)
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
end
