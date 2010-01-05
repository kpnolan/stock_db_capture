# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'analytics/maker'
require 'analytics/builder'
require 'population/builder'
require 'population/maker'
require 'backtest/maker'
require 'backtest/builder'
require 'strategies/base'
require 'yaml'
require 'ruby-prof'

require 'rubygems'
require 'ruby-debug'

class BacktestException < Exception
  def initialize(msg)
    super(msg)
  end
end

class Backtester

  extend TradingCalendar

  attr_accessor :ts, :result_hash, :meta_data_hash

  attr_reader :scan_name, :et_name, :es_name, :xt_name, :xs_name
  attr_reader :etrigger_decl, :opening_decl, :xtrigger_decl, :closing_decl
  attr_reader :desc, :options, :post_process, :days_to_close, :days_to_open, :triggered_index_hash
  attr_reader :entry_trigger, :entry_strategy, :exit_trigger, :exit_strategy
  attr_reader :opening, :closing, :scan, :stop_loss, :tid_array, :date_range, :rsi_id
  attr_reader :position_ts_map
  attr_reader :resolution, :logger
  attr_reader :chunk_id

  #--------------------------------------------------------------------------------------------------------------------
  # A Backtester object is created for every instance of a using(...) statement with the args of that statement along
  # with global values that are set in the backtests(...) block
  #--------------------------------------------------------------------------------------------------------------------
  def initialize(trigger_strategy_name, entry_strategy_name, exit_trigger_name, exit_strategy_name, scan_name, description, options, &block)
    @options = options.reverse_merge :resolution => 1.day, :plot_results => false, :price => :close, :log_flags => :basic,
                                     :days_to_close => 20, :days_to_open => 5, :epass => 0..2, :days_to_optimize => 10,
                                     :pre_buffer => 127, :post_buffer => 20, :repopulate => true
    @et_name = trigger_strategy_name
    @es_name = entry_strategy_name
    @xt_name = exit_trigger_name
    @xs_name = exit_strategy_name
    @scan_name = scan_name

    @desc = description
    @days_to_close = self.options[:days_to_close]
    @days_to_open = self.options[:days_to_open]
    @position_ts_map = { }
    @post_process = block
    @resolution = self.options.delete :resolution
    set_log_level(@options[:log_flags])

    raise BacktestException.new("Cannot find entry trigger: #{et_name}")  if EntryTrigger.find_by_name(et_name).nil?
    raise BacktestException.new("Cannot find entry strategy: #{es_name}") if EntryStrategy.find_by_name(es_name).nil?
    raise BacktestException.new("Cannot find exit trigger: #{xt_name}")   if ExitTrigger.find_by_name(xt_name).nil?
    raise BacktestException.new("Cannot find exit strategy: #{xs_name}")  if ExitStrategy.find_by_name(xs_name).nil?
    raise BacktestException.new("Cannot find scan: #{scan_name}")         if Scan.find_by_name(scan_name).nil?
  end

  #--------------------------------------------------------------------------------------------------------------------
  # Run is called for every instance of a using(...) after the backtester object has config statement in the
  # been initialized form the backtests(...) block and using(...) statement.
  #--------------------------------------------------------------------------------------------------------------------
  def run(chunk_id, logger)
    @logger = logger
    logger.info "\n(#{chunk_id}) Processing backtest with a #{et_name} entry trigger and #{es_name} entry with #{xt_name} trigger and #{xs_name} exit against #{scan_name}"

    @chunk_id       = chunk_id
    @etrigger_decl  = $analytics.find_etrigger(et_name)
    @opening_decl   = $analytics.find_opening(es_name)
    @xtrigger_decl  = $analytics.find_xtrigger(xt_name)
    @closing_decl   = $analytics.find_closing(xs_name)
    @stop_loss_decl = $analytics.find_stop_loss

    @scan           = Scan.find_by_name(scan_name)
    @entry_trigger  = EntryTrigger.find_by_name(et_name)
    @entry_strategy = EntryStrategy.find_by_name(es_name)
    @exit_trigger   = ExitTrigger.find_by_name(xt_name)
    @exit_strategy  = ExitStrategy.find_by_name(xs_name)

    truncate(self.options[:truncate]) unless self.options[:truncate].nil?

    startt = global_startt = Time.now

    # FIXME when a backtest specifies a different set of options, e.g. (:price => :close) we should
    # FIXME invalidate any cached posistions (including and exspecially scans_strategies because the positions will have
    # FIXME totally different values
    #
    # Grab tickers from scans and compute the date range from the scan dates or the options
    # passed in to the constructor (they win)
    #
    sdate = self.options[:start_date] ? self.options[:start_date] : scan.start_date
    edate = self.options[:end_date] ? self.options[:end_date] : scan.end_date

    #--------------------------------------------------------------------------------------------------------------------
    # TRIGGERED POSITION pass. Iterates through a tickers in scan, executing the trigger block for each ticker. Since
    # we're only using an RSI(14) as a triggering signal we execute the block three times varying (in effect) the threshold
    # which, when crossed, tiggers a positioins. The three thresholds used are 20, 25, and 30. The way the thresholds are
    # varied is a hack (FIXME), which should instead involve the use of three seperate trigger strategies instead of the
    # bastardized one we use here.
    #-------------------------------------------------------------------------------------------------------------------
    if entry_trigger.btest_positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "(#{chunk_id}) Beginning trigger positions analysis..." if log? :basic
      RubyProf.start  if self.options[:profile]
      @rsi_id ||= Indicator.lookup(:rsi).id

      count = 0
      for ticker_id in scan.population_ids(options[:repopulate], :logger => logger)
        begin
          ts = Timeseries.new(ticker_id, sdate..edate, resolution, self.options.merge(:logger => logger))
          reset_position_index_hash()
          for pass in self.options[:epass]
            triggered_indexes = ts.instance_exec(etrigger_decl.params, pass, &etrigger_decl.block)
            for index in triggered_indexes
              next if triggered_index_hash.include? index #This index has been triggered on a previous pass
              trigger_date, trigger_price = ts.closing_values_at(index)
              trigger_ival = ts.result_at(index, :rsi)          # We are assuming here that an rsi is the only entry trigger indicator, which may no always be
              # the case
              debugger if trigger_date.nil? or trigger_price.nil?
              position = BtestPosition.trigger_entry(ts.ticker_id, trigger_date, trigger_price, rsi_id, trigger_ival, pass)
              logger.info "Triggered #{ts.symbol} on #{trigger_date.to_formatted_s(:ymd)} at $#{trigger_price}" if log? :triggers
              entry_trigger.btest_positions << position
              scan.btest_positions << position
              map_position_ts(position, ts)
              triggered_index_hash[index] = true
              ts.clear_results() unless ts.nil?
              count += 1
            end
          end
        rescue TimeseriesException => e
          logger.info "#{e.to_s} -- SKIPPING Ticker"
        rescue Exception => e
          logger.info "Unexpected exception #{e.to_s}"
        end

      end

      endt = Time.now
      delta = endt - startt
      logger.info "(#{chunk_id}) #{count} positions triggered -- elapsed time: #{Backtester.format_et(delta)}" if log? :basic

      if self.options[:profile]
        GC.disable
        results = RubyProf.stop
        GC.enable

        File.open "#{RAILS_ROOT}/tmp/trigger-positions.prof", 'w' do |file|
          RubyProf::CallTreePrinter.new(results).print(file)
        end
      end
    else
      logger.info "Using pre-generated triggers..." if log? :basic
    end

    #--------------------------------------------------------------------------------------------------------------------
    # OPEN POSITION pass. Iterates through all positions triggered by the previous pass, running a "confirmation" strategy
    # whose mission it is to cull out losers that have been triggered and ones not likely to close.
    #-------------------------------------------------------------------------------------------------------------------
    if entry_strategy.btest_positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "(#{chunk_id}) Beginning open positions analysis..." if log? :basic
      RubyProf.start  if self.options[:profile]

      startt = Time.now
      count = 0
      duplicate_entries = 0
      triggers = entry_trigger.btest_positions.find(:all, :conditions => { :scan_id => scan.id }, :order => 'ettime, ticker_id')
      trig_count = triggers.length

      for position in triggers
        begin
          start_date = position.ettime
          end_date = BtestPosition.trading_date_from(start_date, days_to_open)
          if ts = timeseries_for(position)
            ts.reset_local_range(start_date, end_date)
          else
            ts = Timeseries.new(position.ticker_id, start_date..end_date, resolution, self.options.merge(:logger => logger))
          end

          confirming_indexes = ts.instance_exec(opening_decl.params, &opening_decl.block)
          unless confirming_indexes.empty?
            index = confirming_indexes.first
            entry_time, entry_price = ts.closing_values_at(index)

            unless BtestPosition.open(position, entry_time, entry_price).nil?
              logger.info format("Position %d of %d (%s) %s\t%d\t%3.2f\t%3.2f\t%3.2f",
                                 count, trig_count, position.ticker.symbol,
                                 position.ettime.to_formatted_s(:ymd),
                                 position.entry_delay, position.etprice, position.entry_price,
                                 position.consumed_margin) if log? :entries
              entry_strategy.btest_positions << position
              count += 1
            end
          else
            logger.info format("Position %d of %d (%s) %s\tNA\t%3.2f\tNA\tNA",
                               count, trig_count, position.ticker.symbol,
                               position.ettime.to_formatted_s(:ymd),
                               position.etprice) if log? :entries
          end
        rescue TimeseriesException => e
          logger.error(e.to_s)
          remove_from_position_map(position)
          BtestPosition.delete position.id
        rescue ActiveRecord::StatementInvalid
          duplicate_entries += 1
          #logger.error("Duplicate entry for #{position.ticker.symbol} tigger: #{position.ettime.to_formatted_s(:ymd)} entry: #{entry_time.to_formatted_s(:ymd)}")
        end
        ts.clear_results unless ts.nil?
      end

      endt = Time.now
      delta = endt - startt
      logger.info "(#{chunk_id}) #{duplicate_entries} duplicate entries merged" if log? :basic
      logger.info "(#{chunk_id}) #{count} positions opened of #{trig_count} triggered -- elapsed time: #{Backtester.format_et(delta)}" if log? :basic

      if self.options[:profile]
        GC.disable
        results = RubyProf.stop
        GC.enable

        File.open "#{RAILS_ROOT}/tmp/open-position.prof", 'w' do |file|
          RubyProf::CallTreePrinter.new(results).print(file)
        end
      end
    else
      logger.info "Using pre-computed entries..."
    end

    #--------------------------------------------------------------------------------------------------------------------
    # TRIGGERED EXIT pass. Iterates through all positions opened by the previous pass applying an exitting strategy based upon
    # crossing a certain threshold of one or more indicators. This is NOT intended to be an optimizing close, rather it records the
    # the time and values at which it crossed a SELL threshold. This often is a threshold crossing which indicates an over-bought
    # condition. The backtest is configured with a certain number of days for this to occur otherwise the position os
    # forcefully closed (usually at a significant loss). Any positions found with an incomplete set of bars is
    # summarily logged and destroyed.
    #-------------------------------------------------------------------------------------------------------------------
    if exit_trigger.btest_positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "(#{chunk_id}) Beginning exit trigger analysis..." if log? :basic
      startt = Time.now

      RubyProf.start if self.options[:profile]

      open_positions = entry_strategy.btest_positions.find(:all, :conditions => { :scan_id => scan.id })
      pos_count = open_positions.length

      counter = 1
      null_exits = 0
      for position in open_positions
        begin
          max_exit_date = BtestPosition.trading_date_from(position.entry_date, days_to_close)
          if max_exit_date > Date.today
            ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
            max_exit_date = ticker_max.localtime
          end
          if ts = timeseries_for(position)
            ts.reset_local_range(position.entry_date, max_exit_date)
          else
            ts_options = { :pre_buffer => Timeseries.prefetch_bars(:rsi, 14), :logger => logger } # FIXME prefetch bars should be dynamic
            ts = Timeseries.new(position.ticker_id, position.entry_date..max_exit_date, resolution, self.options.merge(ts_options))
          end
          exit_time, indicator, ival = ts.instance_exec(xtrigger_decl.params, &xtrigger_decl.block)
          unless exit_time.nil?
            BtestPosition.trigger_exit(position, exit_time, ts.value_at(exit_time, :close), indicator, ival, :closed => true)
            exit_trigger.btest_positions << position
          else
            BtestPosition.trigger_exit(position, max_exit_date, ts.value_at(max_exit_date, :close), nil, nil, :closed => false)
            null_exit = BtestPosition.close(position, max_exit_date, ts.value_at(max_exit_date, :close), nil, :indicator => :rsi, :closed => false)
            if null_exit
              logger.info format("Position %d of %d (%s) %s\t%s has NULL close",
                                 counter, pos_count, position.ticker.symbol,
                                 position.entry_date.to_formatted_s(:ymd),
                                 max_exit_date.to_formatted_s(:ymd))
              null_exits += 1
            end
          end
        rescue TimeseriesException => e
          logger.error("#{e.class.to_s}: #{e.to_s}. DELETING POSITION!")
          remove_from_position_map(position)
          BtestPosition.delete position.id
        end
        ts.clear_results() unless ts.nil?
        logger.info format("Position %d of %d (%s) %s\t%d\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%s",
                           counter, pos_count, position.ticker.symbol,
                           position.entry_date.to_formatted_s(:ymd),
                           position.xtdays_held, position.entry_price, position.xtprice, 0.0,
                           position.xtroi, position.indicator.name ) if log? :exits
        counter += 1
      end

      endt = Time.now
      delta = endt - startt

      logger.info "(#{chunk_id}) #{null_exits} NULL EXITS found" if log? :basic
      logger.info "(#{chunk_id}) Exit trigger analysis elapsed time: #{Backtester.format_et(delta)}" if log? :basic

      if self.options[:profile]
        GC.disable
        results = RubyProf.stop
        GC.enable

        File.open "#{RAILS_ROOT}/tmp/exit-trigger.prof", 'w' do |file|
          RubyProf::CallTreePrinter.new(results).print(file)
        end
      end
    else
      logger.info "Using pre-computed exits..."
    end

    #--------------------------------------------------------------------------------------------------------------------
    # CLOSE POSITION pass. Once a position has crossed  a exit threshold it is further processed to seek an optimal close,
    # not just the point at which an arbritary threshold was crossed. This is usually done by followin an indicator as it rises and
    # finally peeks or levels off. At this point we close the position on this pass. The theory being that there's still
    # some headroom betwen the triggered exit threshold and the max value an indicator is known to likely reach. Alternatively
    # we could just raise our exit threshold, but we run the risk of never reaching them and winding up with un-closed positions.
    # This pass is a compromise between to two. One we reach an exit threshold it's likely that we are already in a profit
    # position. The purpose of this pass is to follow the curse looking for a local maxima and then closing, thus added
    # to our profit.
    #-------------------------------------------------------------------------------------------------------------------
    if exit_strategy.btest_positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "(#{chunk_id}) Beginning close position optimization analysis..." if log? :basic
      startt = Time.now

      RubyProf.start if self.options[:profile]

      open_positions = exit_trigger.btest_positions.find(:all, :conditions => { :scan_id => scan.id },
                                                         :include => :ticker, :order => 'tickers.symbol, entry_date')
      pos_count = open_positions.length

      counter = 1
      log_counter = 0
      for position in open_positions
        begin
          p = position
          max_exit_date = BtestPosition.trading_date_from(position.xttime, options[:days_to_optimize])
          if max_exit_date > Date.today
            ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
            max_exit_date = ticker_max.localtime
          end
          if ts = timeseries_for(position)
            ts.reset_local_range(position.xttime, max_exit_date)
          else
            ts = Timeseries.new(position.ticker_id, position.xttime..max_exit_date, resolution, self.options.merge(:logger => logger))
          end
          index = ts.instance_exec(position, closing_decl.params, &closing_decl.block)

          unless index.nil?
            closing_time, closing_price = ts.closing_values_at(index)
            max_rsi = ts.result_at(index, :rsi)
          else
            closing_time = position.xttime
            closing_price = postition.xtprice
            max_rsi = xtival
          end
          BtestPosition.close(position, closing_time, closing_price, max_rsi, :indicator => :rsi, :closed => true)
          begin
            exit_strategy.btest_positions << position
          rescue Exception   # FIXME duplicates should have been filtered out on opening, so we should not have to do this
            remove_from_position_map(position)
            BtestPosition.delete position.id
          end
          ts.clear_results() unless ts.nil?

          if position.exit_date > position.xttime
            xtival = position.xtival.nil? ? -0.00 : position.xtival.abs > 100.0 ? -0.00 : position.xtival
            logger.info("\t\t\t\t\t\tDH\tXTROI\tDELTA\tROI\tXTIVAL\tRSI") if log?(:closures) and log_counter % 50 == 0
            logger.info format("Position %d of %d (%s)\t%s\t%d\t%3.2f%%\t%3.2f\t%3.2f%%\t%3.2f\t%3.2f\t%s",
                               counter, pos_count, position.ticker.symbol,
                               position.xttime.to_formatted_s(:ymd), position.exit_days_held,
                               position.xtroi*100, position.exit_delta, position.roi*100,
                               xtival , position.exit_ival, position.xtind.name) if log? :closures
            log_counter += 1 if log? :closures
          elsif position.exit_date < position.xttime
            xtival = position.xtival.nil? ? -0.00 : position.xtival.abs > 100.0 ? -0.00 : position.xtival
            logger.info format("!!!Position %d of %d (%s)\t%s %s\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%s",
                               counter, pos_count, position.ticker.symbol,
                               position.xttime.to_formatted_s(:ymd), position.exit_date.to_formatted_s(:ymd),
                               position.xtprice, position.exit_price,
                               xtival , position.exit_ival, position.xtind.name) if log? :closures
          end
        rescue TimeseriesException => e
          logger.error("#{e.class.to_s}: #{e.to_s}. DELETING POSITION!")
          remove_from_position_map(position)
          BtestPosition.delete position.id
        end
        counter += 1
      end
    end

    endt = Time.now
    delta = endt - startt
    logger.info "(#{chunk_id}) Backtest (optimize close analysis) elapsed time: #{Backtester.format_et(delta)}" if log? :basic

    #-----------------------------------------------------------------------------------------------------------------
    # Persist the closed positions to the disk resident Positions table by walking through the positions in the
    # position map and writing out only those which closed
    #-----------------------------------------------------------------------------------------------------------------
    startt = Time.now

    columns = BtestPosition.columns.map(&:name)
    columns.delete 'id'

    #TODO replace this entire block with a single constructed INSERT stmt with conditions on scan_id and exit_date
    #TODO see Position.generate_insert_sql

    position_ids = scan.btest_position_ids
    for position_id in position_ids
      if (position = BtestPosition.find_by_id(position_id)) && position.exit_date
        attrs = columns.inject({}) { |h,k| h[k] = position[k]; h }
        begin
          Position.create! attrs
        rescue ActiveRecord::StatementInvalid
          logger.error("Duplicate entry for #{position.ticker.symbol} tigger: #{position.entry_date.to_formatted_s(:ymd)}")
        end
      end
    end
    #BtestPosition.delete_all(:scan_id => scan.id) #clean up after ourselves

    endt = Time.now
    delta = endt - startt
    logger.info "Backtest (persist positions) elapsed time: #{Backtester.format_et(delta)}" if log? :basic


    #-----------------------------------------------------------------------------------------------------------------
    # Generate statistics to support positions
    #-----------------------------------------------------------------------------------------------------------------
    generate_stats(exit_strategy.btest_positions) if self.options[:generate_stats]

    endt = Time.now
    global_delta = endt - global_startt
    logger.info "(#{chunk_id}) Total Backtest elapsed time: (#{scan_name}) #{Backtester.format_et(global_delta)}" if log? :basic
    #--------------------------------------------------------------------------------------------------------------------
    # Stop-loss pass. The nitty gritty of threshold crossing is handeled by tstop(...)
    #-------------------------------------------------------------------------------------------------------------------
    unless stop_loss.nil? || stop_loss.threshold.to_f == 100.0
      logger.info "Beginning stop loss analysis..."
      startt = Time.now
      open_positions = exit_strategy.btest_positions.find(:all, :conditions => { :scan_id => scan.id })
      open_positions.each do |p|
        tstop(p, stop_loss.threshold, stop_loss.options)
      end
      endt = Time.now
      delta = endt - startt
      deltam = delta/60.0
      logger.info "Backtest (stop loss analysys) elapsed time: #{deltam} minutes" if log? :basic
    end
    #--------------------------------------------------------------------------------------------------------------------
    # Post processing which not only includes make_sheet(...)
    #-------------------------------------------------------------------------------------------------------------------
    if post_process
      logger.info "(#{chunk_id}) Beginning post processing (make_sheet)..." if log? :basic
      startt = Time.now

      post_process.call(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan) if post_process

      endt = Time.now
      delta = endt - startt

      logger.info "(#{chunk_id}) Post processing (make_sheet) elapsed time: #{Backtester.format_et(delta)}" if log? :basic
    end
  end

  #
  # Reset the hash containing the indexes of all positions opened for a particular timeseries
  #
  def reset_position_index_hash
    @triggered_index_hash = { }
  end

  #--------------------------------------------------------------------------------------------------------------------
  # Truncate all positions matching the current tigger, entry, or exit strategies or scan. Accepts either a single symbol or an array of symbols
  #--------------------------------------------------------------------------------------------------------------------
  def truncate(symbol_or_array)
    symbol_or_array = [ symbol_or_array ] unless symbol_or_array.is_a? Array
    total_count = count = 0
    startt = Time.now

    symbol_or_array.each do |symbol|
      name = send(symbol).name
      logger.info "(#{chunk_id}) Begining truncate of #{name}..." if log? :basic
      case symbol
      when :entry_trigger then
        count += entry_trigger.positions.count
        count += entry_trigger.btest_positions.count
        entry_trigger.positions.clear
        entry_trigger.btest_positions.clear
      when :entry_strategy then
        count += entry_strategy.positions.count
        count += entry_strategy.btest_positions.count
        entry_strategy.positions.clear
        entry_strategy.btest_positions.clear
      when :exit_trigger then
        count += exit_trigger.positions.count
        count += exit_trigger.btest_positions.count
        exit_trigger.positions.clear
        exit_trigger.btest_positions.clear
      when :exit_strategy then
        count += exit_strategy.positions.count
        count += exit_strategy.btest_positions.count
        exit_strategy.positions.clear
        exit_strategy.btest_positions.clear
      when :scan then
        count += scan.positions.count
        count += scan.btest_positions.count
        scan.positions.clear
        scan.btest_positions.clear
      else
        raise ArgumentError, ":truncate must take one or an array of the following: :entry_trigger, :entry_strategy, :exit_strategy or :scan"
      end
      total_count += count
    end
    delta = Time.now - startt
    logger.info "(#{chunk_id}) Truncated #{total_count} positions in #{Backtester.format_et(delta)}" if log? :basic
  end
  #--------------------------------------------------------------------------------------------------------------------
  # Geerate statistics recorded are given by the params given to the function compute_and_persist
  #--------------------------------------------------------------------------------------------------------------------
  def generate_stats(positions)
    logger.info "(#{chunk_id}) Beginning indicator statistics generatian..."
    startt = Time.now
    for position in positions
      start_date = BtestPosition.trading_date_from(position.ettime, -10)
      end_date = BtestPosition.trading_date_from(position.exit_date, 10)
      if end_date > Date.today
        ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
        end_date = ticker_max.localtime
      end
      ts = Timeseries.new(position.ticker_id, start_date..end_date, 1.day, :post_buffer => 0)
      ts.compute_and_persist(position,
                             :macdfix => { :result => :macd_hist },
                             :rsi => { :result => :rsi },
                             :rvi => { :result => :rvi })
    end
    endt = Time.now
    delta = endt-startt
    logger.info "(#{chunk_id}) Generate Position Statitics took #{Backtester.format_et(delta)}" if log? :basic
  end

  #--------------------------------------------------------------------------------------------------------------------
  # add a mapping between a positions and it's associated timeseries
  #--------------------------------------------------------------------------------------------------------------------
  def map_position_ts(position, timeseries)
    # FIXME !!! commented this line out because recycling timeseries is broken
    #self.position_ts_map[position.id] = timeseries
  end

  #--------------------------------------------------------------------------------------------------------------------
  # retrieve the timeseries for this positions that was stored in the prior method
  #--------------------------------------------------------------------------------------------------------------------
  def timeseries_for(position)
    position_ts_map[position.id]
  end

  #--------------------------------------------------------------------------------------------------------------------
  # retrieve the timeseries for this positions that was stored in the prior method
  #--------------------------------------------------------------------------------------------------------------------
  def remove_from_position_map(position)
    self.position_ts_map.delete position.id
  end

  #--------------------------------------------------------------------------------------------------------------------
  # set the log of the type (not the importance) of the log messages output types are:
  #     basic, entries, exis,
  #--------------------------------------------------------------------------------------------------------------------
  def set_log_level(flags)
    options = %w{none basic triggers entries exits closures}.map(&:to_sym)
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
  def Backtester.format_et(seconds)
    if seconds > 60.0 and seconds < 120.0
      format('%d minute and %d seconds', (seconds/60).floor, seconds.to_i % 60)
    elsif seconds > 120.0
      format('%d minutes and %d seconds', (seconds/60).floor, seconds.to_i % 60)
    else
      format('%2.2f seconds', seconds)
    end
  end
  #--------------------------------------------------------------------------------------------------------------------
  # validates the values of the three trigger based strategies
  #--------------------------------------------------------------------------------------------------------------------
  def validate_config(triples)
    triples.each do |triple|
      use, name, value = triple
      raise ArgumentError, "#{use.to_s.capitalize} strategy #{name} do not have a value" if value.nil?
    end
  end

  #--------------------------------------------------------------------------------------------------------------------
  # First attempt at a stop-loss algorithm that mimics the stop-losses which can be placed on orders at the time the are
  # bought and/or applied and modified later. Early tests indicated that this type of loss protection did more harm than
  # good targetting many otherwise profitable trades
  #--------------------------------------------------------------------------------------------------------------------
  def tstop(p, threshold_percent, options={})
    options.reverse_merge! :resolution => 30.minutes, :max_days => 30
    tratio = threshold_percent / 100.0
    etime = p.entry_date
    # determine if this position was entered during trading hours or at the end of the day
    # if so, calculate the bar_index (based upon resolution) of that day, or start with
    # the following day at index 0
    if etime.in_trade? && !etime.eod?
      sindex = ttime2index(etime, res)
      edate = p.entry_date.to_date
    else
      sindex = 0
      edate = Backtester.trading_date_from(etime.to_date, 1)
    end
    max_date = p.exit_date.nil? ? Backtester.trading_date_from(edate, options[:max_days]) : p.exit_date.to_date
    etime = p.entry_date
    # grab a timeseries at the given resolution from the entry date (or following day)
    # through the number of specified trailing days
    begin
      ts = Timeseries.new(p.ticker.symbol, edate..max_date, options[:resolution])
      max_high = p.entry_price
      while sindex < ts.length
        high, low = ts.values_at(sindex, :high, :low)
        max_high = max_high > high ? max_high : high
        if (rratio = (max_high - low) / max_high) > tratio
          xtime = ts.index2time(sindex)
          xdate = xtime.to_date
          edate = p.entry_date.to_date
          days_held = BtestPosition.trading_day_count(edate, xdate)
          nreturn = ((low - p.entry_price) / p.entry_price) if days_held.zero?
          nreturn = ((low - p.entry_price) / p.entry_price) / days_held if days_held > 0
          ret = ((low - p.entry_price) / p.entry_price)
          nreturn *= -1.0 if p.short and nreturn != 0.0
          logger.info(format("%s\tentry: %3.2f max high: %3.2f low(exit): %3.2f on drop: %3.3f %%\t return: %3.3f %%\t @ #{xtime.to_s(:short)}",
                              ts.symbol, p.entry_price, max_high, low, 100*rratio, ret*100.0)) if log? :stops
          p.update_attributes!(:exit_price => low, :exit_date => xtime,
                               :days_held => days_held, :nreturn => nreturn,
                               :exit_trigger => rratio, :stop_loss => true)

          break;
        end
        sindex += 1
      end
    rescue TimeseriesException => e
      logger.info e.to_s
    rescue Exception => e
      logger.info e.to_s
    end
    nil
  end
end
