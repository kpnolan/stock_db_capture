require 'rubygems'
require 'daemons'
require 'rinda/ring'
require 'monitor'
require 'backtest_config'
require 'backtest/message'
require 'backtest/result'
require 'backtest/exceptions'

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


module Backtest
  module Consumer
    class Base
      include BacktestConfig

      attr_reader :options, :post_process
      attr_reader :config_prefix, :config, :tuplespace
      attr_reader :threads, :logger
      attr_accessor :proc_id

      #--------------------------------------------------------------------------------------------------------------------
      # The constructor for a daemon class. Since the worker daemons are forked, they get a copy of the process start which
      # of course includes the state stored here. The serve() method actually invokes a separate process.
      #--------------------------------------------------------------------------------------------------------------------
      def initialize(config_file)
        @config_prefix = File.basename(config_file, '.cfg')
        @config = BacktestConfig.load(config_file)

        @options = config.options.reverse_merge :verbose => false
        #create readers for each of the above options
        self.extend self.options.to_mod

        DRb.start_service
        ring_server = Rinda::RingFinger.primary
        ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
        @tuplespace = Rinda::TupleSpaceProxy.new ts
        Message.bind_to_tuplespace(tuplespace)
        Message.bind_to_config(config)
        Message.default_timeout = 10
        Result.bind_to_tuplespace(tuplespace)
        Result.default_timeout = 10

        @threads = []
        @threads.extend(MonitorMixin)
        Thread.abort_on_exception = true
      end

      #--------------------------------------------------------------------------------------------------------------------
      # The serve function is called as the entry point for any number of worker daemons, each responding to messages and
      # storing results back into NUMA memory.
      #--------------------------------------------------------------------------------------------------------------------
      def serve(proc_id)
        @proc_id = proc_id
        # Create a Mutex for puts output
        @o = Object.new
        @o.extend(MonitorMixin)
        log_path = File.join(RAILS_ROOT, 'log', "#{config_prefix}_#{proc_id}.log")
        system("cat /dev/null > #{log_path}")
        @logger = ActiveSupport::BufferedLogger.new(log_path)

        # Strip off all :source nodes since they are relagated to the producer process(s)
        startt = global_startt = Time.now
        consumer_stages = config.tsort.map { |name| config[name] }.drop_while { |node| node.type == :source || node.type == :scan }

        # Create a thread for each stage in the config file, i.e. filter, exit, close. The semantics of that thread
        # is contained in the node object (which is build by reading the config file
        consumer_stages.each { |node| stage(node) }

        # Wait until all the threads timeout (nothing left to do)
        threads.each { |thread| thread.join }
        endt = Time.now
        delta = endt - startt
        info "#{options[:app_name]} total elapsed time #{Base.format_et(delta)}"
      end
      #
      # Synchronized access to the $stdout stream (so Threads don't trample output to gibberise
      #
      def info(str)
        @o.synchronize { $stdout.puts "INFO: #{str}"; $stdout.flush }
      end
      #
      # Synchronized access to the $stdout stream (so Threads don't trample output to gibberise
      #
      def error(str)
        @o.synchronize { $stdout.puts "ERROR: #{str}"; $stdout.flush }
      end
      #
      # A Thread is dedicated to each named block in the configuration file. The threads just wait until a message shows up with
      # thier "name" on it, extra the relavent runtime information and the call the block of Ruby code associated with that message.
      # A node has a type with loose describes is symantas although the actuall clode is a function of the template specified for that node
      # and the code proper given with the node delarations. Resutls of blocks are treated like messages, i.e. a code block waits for the result to
      # show up before the code block and proceed anty further.
      #
      def stage(node)
        Thread.new(node) do |node|
          threads.synchronize { threads.push(Thread.current) }
          next_stages, block = node.outputs, node.meta_block
          count = 0
          startt = Time.now
          loop do
            begin
              msg = Message.receive(node)
              info("received #{msg.type} -- #{msg.name} #{msg.position.class} #{count}") if verbose && msg.type == :close
              if msg.body?
                results = msg.eval_body(self)
                status = msg.interpret_results(results)
              else
                status = true
              end
              next_stages.each { |next_stage| msg.send_to_stage(next_stage) if next_stage && status }
              count += 1
            rescue Rinda::RequestExpiredError => e
              error("Rinda Timeout: #{e}")
              endt = Time.now
              delta = endt - startt
              info "#{node.type} - #{node.name} #{count} positions processed -- elapsed time: #{Base.format_et(delta)}"
              Thread.current.terminate
            rescue Backtest::RuntimeException => e
              error("#{e.class}: #{e.message}")
              logger.error("#{e.class}: #{e.message}")
            end
         end
        end
      end
      def Base.run(config_path)
        options = {
          :dir_mode => :normal,
          :dir => File.join(RAILS_ROOT, 'log'),
          :multiple => true,
          :log_output => true,
          :baacktrace => true,
          :ontop => true
        }
        #1.times do
        #  Daemons.run_proc('backtest_consumer', options) {
        server = Base.new(config_path)
        server.serve(0)
        #  }
        #end
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
end

