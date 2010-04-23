require 'backtest_config'
require 'strategies/base'
require 'yaml'

require 'rubygems'
require 'daemons'
require 'rinda/ring'

module Backtest
  module Producer
    class Base
      extend TradingCalendar
      include BacktestConfig

      attr_accessor :tuplespace

      attr_reader :scan_name
      attr_reader :desc, :options, :triggered_index_hash, :max_date
      attr_reader :scan, :tid_array, :date_range, :rsi_id
      attr_reader :position_ts_map
      attr_reader :resolution, :logger, :config_file, :config
      attr_reader :debug, :next_ids

      #--------------------------------------------------------------------------------------------------------------------
      # A Backtester object is created for every instance of a using(...) statement with the args of that statement along
      # with global values that are set in the backtests(...) block
      #--------------------------------------------------------------------------------------------------------------------
      def initialize(config_file)
        @config = BacktestConfig.load(config_file)
        @options = config.options.reverse_merge :resolution => 1.day, :price => :close, :log_flags => [:basic ],
                                                :days_to_open => 5, :epass => 0..0, :truncate => true,
                                                :pre_buffer => 0, :post_buffer => 0, :repopulate => true,
                                                :max_date => (Date.today-1),:record_indicators => false,
                                                :debug => false


        @resolution = self.options.delete :resolution
        @max_date = @options[:max_date]
        @debug = @options[:debug]
        set_log_level(@options[:log_flags])

        Position.delete_all if options[:truncate]

        DRb.start_service
        ring_server = Rinda::RingFinger.primary
        puts 'found ringserver'
        ts = ring_server.read([:name, :TupleSpace, nil, nil])[2]
        @tuplespace = Rinda::TupleSpaceProxy.new ts
        puts 'found tuplespace'

        for source in config.sources
          for scan in config.scans
            run(source, scan)
          end
        end
      end

      #--------------------------------------------------------------------------------------------------------------------
      # TRIGGERED POSITION pass. Iterates through a tickers in scan, executing the trigger block for each ticker. Since
      # we're only using an RSI(14) as a triggering signal we execute the block three times varying (in effect) the threshold
      # which, when crossed, tiggers a positioins. The three thresholds used are 20, 25, and 30. The way the thresholds are
      # varied is a hack (FIXME), which should instead involve the use of three seperate trigger strategies instead of the
      # bastardized one we use here.
      #-------------------------------------------------------------------------------------------------------------------
      def run(source, scan)
        options = {
          :app_name => "#{config_file}_producer_#{scan.name}",
          :dir_mode => :normal,
          :dir => File.join(RAILS_ROOT, 'log'),
          :multiple => true,
          :log_output => true,
          :baacktrace => true,
          :ontop => true
        }
        #Daemons.daemonize(options)

        sdate = scan.start_date
        edate = scan.end_date
        puts "(#{scan.name}) Beginning trigger positions analysis..." if log? :basic
        primary_indicator = source.params[:result] && source.params[:result].first
        indicator_id ||= Indicator.lookup(primary_indicator).id

        count = 0
        index_count = 0
        ticker_ids = scan.population_ids(options[:repopulate], :logger => logger)
        @next_ids ||= config.next_id_pairs(source)
        startt = Time.now
        for ticker_id in ticker_ids
          begin
            ts = Timeseries.new(ticker_id, sdate..edate, resolution, self.options.merge(:logger => logger))
            reset_position_index_hash()
            for pass in self.options[:epass]
              triggered_indexes = ts.instance_exec(source.params, pass, &source.block)
              index_count = triggered_indexes.length
              for index in triggered_indexes
                next if triggered_index_hash.include? index #This index has been triggered on a previous pass
                trigger_date, trigger_price = ts.closing_values_at(index)
                trigger_ival = ts.result_at(index, primary_indicator)
                # the case
                debugger if trigger_date.nil? or trigger_price.nil?
                position = Position.trigger_entry(ts.ticker_id, trigger_date, trigger_price, indicator_id, trigger_ival, pass)
                next_ids.each { |next_id| position.write_tuple(tuplespace, *next_id) }
                puts "writing tuple #{count}"
                logger.info "Triggered #{ts.symbol} on #{trigger_date.to_formatted_s(:ymd)} at $#{trigger_price}" if log? :triggers
                ts.persist_results(entry_trigger, position, *etrigger_decl.params[:result]) if options[:record_indicators]
                count += 1
                triggered_index_hash[index] = true
              end
            end
          rescue TimeseriesException => e
            puts "#{e.to_s} -- SKIPPING Ticker"
          rescue ActiveRecord::StatementInvalid
            puts("Duplicate entry for #{ts.symbol} on #{trigger_date.to_formatted_s(:ymd)} ent_id: #{indicator_id}")
          end
          symbol = Ticker.find(ticker_id).symbol
          puts("Processed #{symbol} #{count} of #{ticker_ids.length} #{index_count} positions entered") if log? :trigger_summary
        end
        endt = Time.now
        delta = endt - startt
        puts "(#{scan.name}) #{count} positions triggered -- elapsed time: #{Base.format_et(delta)}" if log? :basic
        Process.exit
      end
      #
      # Reset the hash containing the indexes of all positions opened for a particular timeseries
      #
      def reset_position_index_hash
        @triggered_index_hash = { }
      end

      #--------------------------------------------------------------------------------------------------------------------
      # set the log of the type (not the importance) of the log messages output types are:
      #     basic, entries, exis,
      #--------------------------------------------------------------------------------------------------------------------
      def set_log_level(flags)
        options = %w{none basic triggers trigger_summary entries exits closures}.map(&:to_sym)
        flags = Array.wrap(flags)
        unless flags.all? { |flag| options.member? flag }
          flags.each do |flag|
            unless options.member? flag
              raise ArgumentError, "log level :#{flag} is not one of the support options: #{options.join(', ')}"
            end
          end
        end
        @log_flags = flags
      end
      #--------------------------------------------------------------------------------------------------------------------
      # Predicate which determines whether a particular event should be logged by the contents of the @log_flags array
      #--------------------------------------------------------------------------------------------------------------------
      def log?(flag)
        @log_flags.member? flag
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
