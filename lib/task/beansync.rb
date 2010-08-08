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

    delegate :info, :error, :debug, :to => :logger

    attr_reader :options, :post_process
    attr_reader :config_basename, :config
    attr_reader :con_pool, :ip_addrs, :thpool, :ptasks, :ctasks, :consumers, :producers, :jobq
    attr_reader :logger
    attr_accessor :proc_id, :deferred_jobs, :completed_defers, :prev_counts

    #--------------------------------------------------------------------------------------------------------------------
    # The constructor for a daemon class. Since the worker daemons are forked, they get a copy of the process start which
    # of course includes the state stored here. The serve() method actually invokes a separate process.
    #--------------------------------------------------------------------------------------------------------------------
    def initialize(config_file, proc_id)
      @config_basename = File.basename(config_file)
      @config = Dsl.load(config_file)
      @proc_id = proc_id
      @thpool = ThreadPool.new(THREAD_POOL_SIZE)
      @deferred_jobs = 0
      @completed_defers = 0
      @jobq = ::Queue.new
      @ip_addrs = nil
      @con_pool = nil
      @options = config.options.reverse_merge :verbose => false, :logger_type => :remote, :message_timeout => 30
      #create readers for each of the above options
      self.extend self.options.to_mod

      @logger = initialize_logger()

      Message.bind_config(config)
      Message.attach_logger(logger)
      Timeseries.attach_logger(logger)
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
        # Extract producers and consumers from task topoloty
        #
        @ptasks = tasks.select { |task| task.parent.nil? && proc_id.zero? }
        @ctasks = tasks.select { |task| task.parent }
        #
        # Set up the connection pool
        #
        @con_pool = ConnectionPool.new(ctasks.map(&:name), 1)
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
        @stats_thread = Thread.fork(0) { |tcount|
          Thread.current[:name] = 'stats'
          loop do
            sleep(10)
            begin
              total_defers = 0
              sent_to = Message.to_task_count.dup
              consumers.each do |c|
                name = c.task.name
                defers = c.stats.deferred
                recv = c.stats.recv
                rcnt = c.stats.results_len
                sent = sent_to.include?(name) ? sent_to[name] : 0
                total_defers += defers
                str = format('[%1d:%2d]%22s  Defers: %5d Messages sent:recv %5d:%5d:%d', proc_id, tcount, name, defers,sent,recv,rcnt)
                puts str
              end
              sent = Message.sent_messages
              recv = Message.received_messages
              str = format('[%1d:%2d] %37sMessages sent:recv %5d:%5d   Jobs:Queued:Results %5d:%5d:%5d',
                           proc_id, tcount, ' ',sent, recv, jobq.size, thpool.job_count, thpool.result_count)
              puts str
              puts "Find thread status: #{$t.status}" if $t
              puts ''
              $stdout.flush
            rescue Exception => e
              $stderr.puts e
              $stderr.puts(e.backtrace.join("\n"))
            end

            #if no_activity?(Message.sent_messages, Message.received_messages, total_defers)
            #  puts "No message activity...initiating stop"
            #  finish(startt)
            #end
            tcount += 1
          end
        }
        #
        # Main loop
        #
        puts "Entering Main Loop"; $stdout.flush
        loop {
          thpool.run_deferred_callbacks()
          thpool.defer(*jobq.pop) until jobq.empty?
          sleep(0.001)
        }
        #
        # And that's all folks...
        #
      rescue => e
        $stderr.puts "#{e.class}: #{e.message}"
        $stderr.puts(e.backtrace.join("\n"))
        raise
      end

      #
      # Wait until all the threads timeout with either means that there is nothing left to do or some unrecoverable
      # error was encounted
      #
      def no_activity?(*counts)
        self.prev_counts ||= Array.new(counts.length)
        defers = counts.last
        @repeats ||= 0
        status = defers.zero? && (prev_counts == counts ? true : (self.prev_counts = counts and false))
        status ? @repeats += 1 : repeats = 0
        @repeats == 3
      end

      def generaate_socket_addrs(ipaddr=DEFAUL_ADDR, port=DEFAULT_PORT, count=POOL_SIZE)
        addr_ary = []
        count.times { addr_ary << "#{ipaddr}:#{port}" }
        addr_ary
      end

      def finish(startt)
        endt = Time.now
        delta = endt - startt
        info "#{options[:app_name]} total elapsed time #{Base.format_et(delta)}"
        con_pool.status.each_pair { |k,v| puts "#{k}:\t#{v}"}
      end
    end

    def Base.run(config_path, server_count)
      Base.env_check()
      #
      # TODO we might want to go through the hassle of creating ApplicationOjbects and ApplicationsGroups (which have one 7monitor)
      #
      child_count = server_count - 1
      child_count.times do |child_index|
        Process.fork do
          ActiveRecord::Base.connection.reconnect!
          Base.exec(config_path, child_index)
        end
      end
      if child_count > 0
        p Process.waitall
      else
        Signal.trap('INT') { con_pool.close; exit }
        Signal.trap('TERM'){ con_pool.close; exit }
        Base.exec(config_path, 0)
      end
    end

    def Base.exec(config_path, child_index)
      server = Base.new(config_path, child_index)
      server.serve()
      #server.serve(:starter, :scan_gen)#,:timeseries_args, :rsi_trigger_14)
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
    def Base.env_check
      unless Position.count.zero?
        $stderr.puts "Position table is not empty! (needs to be truncated first)"
        exit(5)
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
