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
  attr_reader :scan_name, :ts_name, :es_name, :xs_name, :desc, :options, :post_process, :days_to_close, :days_to_open, :triggered_index_hash
  attr_reader :trigger_strategy, :entry_strategy, :exit_strategy, :trigger, :opening, :closing, :scan, :stop_loss, :tid_array, :date_range
  attr_reader :resolution, :logger

  #--------------------------------------------------------------------------------------------------------------------
  # A Backtester object is created for every instance of a using(...) statement with the args of that statement along
  # with global values that are set in the backtests(...) block
  #--------------------------------------------------------------------------------------------------------------------
  def initialize(trigger_strategy_name, entry_strategy_name, exit_strategy_name, scan_name, description, options, &block)
    @options = options.reverse_merge :resolution => 1.day, :plot_results => false, :price => :close, :log => :basic,
                                     :days_to_close => 30, :days_to_open => 5, :epass => 0..2
    @ts_name = trigger_strategy_name
    @es_name = entry_strategy_name
    @xs_name = exit_strategy_name
    @scan_name = scan_name
    @desc = description
    @days_to_close = self.options[:days_to_close]
    @days_to_open = self.options[:days_to_open]
    @positions = []
    @post_process = block
    @resolution = self.options.delete :resolution
    set_log_level(@options[:log])

    raise BacktestException.new("Cannot find strategy: #{ts_name}") if TriggerStrategy.find_by_name(ts_name).nil?
    raise BacktestException.new("Cannot find strategy: #{es_name}") if EntryStrategy.find_by_name(es_name).nil?
    raise BacktestException.new("Cannot find strategy: #{ex_name}") if ExitStrategy.find_by_name(xs_name).nil?
    raise BacktestException.new("Cannot find scan: #{scan_name}") if Scan.find_by_name(scan_name).nil?
  end

  #--------------------------------------------------------------------------------------------------------------------
  # Run is called for every instance of a using(...) after the backtester object has config statement in the
  # been initialized form the backtests(...) block and using(...) statement.
  #--------------------------------------------------------------------------------------------------------------------

  def run(logger)
    @logger = logger
    logger.info "\nProcessing backtest with a #{ts_name} trigger and #{es_name} entry with #{xs_name} exit against #{scan_name}"
    @trigger = $analytics.find_trigger(ts_name)
    @opening = $analytics.find_opening(es_name)
    @closing = $analytics.find_closing(xs_name)
    @stop_loss = $analytics.find_stop_loss
    #
    # Validate that all three strategies agree with what was passed into the "using(...)" statement
    #
    strategy_use = [:trigger, :opening, :closing]
    strategy_names = [ts_name, es_name, xs_name ]
    strategy_values = [ trigger, opening, closing ]
    strategy_bindings = strategy_use.zip(strategy_names, strategy_values)
    validate_config(strategy_bindings)

    @scan = Scan.find_by_name(scan_name)
    @trigger_strategy = TriggerStrategy.find_by_name(ts_name)
    @entry_strategy = EntryStrategy.find_by_name(es_name)
    @exit_strategy = ExitStrategy.find_by_name(xs_name)

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

    if trigger_strategy.positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "Beginning trigger positions analysis..." if log? :basic
      RubyProf.start  if self.options[:profile]

      count = 0
      for ticker_id in scan.population_ids(false, :logger => logger)
        ts = Timeseries.new(ticker_id, sdate..edate, resolution, self.options.merge(:logger => logger))
        reset_position_index_hash()
        for pass in self.options[:epass]
          triggered_indexes = ts.instance_exec(trigger.params, pass, &trigger.block)
          for index in triggered_indexes
            next if triggered_index_hash.include? index #This index has been triggered on a previous pass
            trigger_date, trigger_price = ts.closing_values_at(index)
            debugger if trigger_date.nil? or trigger_price.nil?
            position = Position.trigger(ts.ticker_id, trigger_date, trigger_price, pass)
            trigger_strategy.positions << position
            scan.positions << position
            triggered_index_hash[index] = true
            count += 1
          end
        end
      end

      endt = Time.now
      delta = endt - startt
      logger.info "#{count} positions triggered -- elapsed time: #{format_et(delta)}" if log? :basic

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

    if entry_strategy.positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "Beginning open positions analysis..."
      RubyProf.start  if self.options[:profile]

      startt = Time.now

      count = 0
      triggers = trigger_strategy.positions.find(:all, :conditions => { :scan_id => scan.id }, :order => 'triggered_at, ticker_id')
      trig_count = triggers.length

      for position in triggers
        begin
          start_date = position.triggered_at
          end_date = Position.trading_date_from(start_date, days_to_open)
          ts = Timeseries.new(position.ticker_id, start_date..end_date, resolution, self.options.merge(:logger => logger))

          confirming_indexes = ts.instance_exec(opening.params, &opening.block)
          unless confirming_indexes.empty?
            index = confirming_indexes.first
            entry_time, entry_price = ts.closing_values_at(index)
            Position.open(position, entry_time, entry_price)
            logger.info format("Position %d of %d (%s) %s\t%d\t%3.2f\t%3.2f\t%3.2f",
                               count, trig_count, position.ticker.symbol,
                               position.triggered_at.to_formatted_s(:ymd),
                               position.entry_delay, position.trigger_price, positioin.entry_price,
                               position.consumed_margin) if log? :entries
            entry_strategy.positions << position
            count += 1
          else
            logger.info format("Position %d of %d (%s) %s\t%s\t%3.2f\t%s\t%s",
                               count, trig_count, position.triggered_at.to_formatted_s(:ymd),
                               'NA', position.trigger_price, 'NA', 'NA'  ) if log? :entries
          end
        rescue TimeseriesException => e
          logger.error(e.to_s)
          position.destroy
        end
      end

      endt = Time.now
      delta = endt - startt
      logger.info "#{count} positions opened of #{trig_count} triggered -- elapsed time: #{format_et(delta)}" if log? :basic

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
    # CLOSE POSITION pass. Iterates through all positions opened by the previous pass closing them on (hopefully) a bar
    # which a maximum (or close to it) profit. At present, opened positions are given 30 trading days to close whereup
    # they are forcefully closes (usually at a significant loss). Any positions found with an incomplete set of bars is
    # summarily logged and destroyed.
    #-------------------------------------------------------------------------------------------------------------------
    if exit_strategy.positions.find(:all, :conditions => { :scan_id => scan.id }).count.zero?
      logger.info "Beginning close positions analysis..." if log? :basic
      startt = Time.now

      RubyProf.start if self.options[:profile]

      open_positions = entry_strategy.positions.find(:all, :conditions => { :scan_id => scan.id })
      pos_count = open_positions.length

      counter = 1
      for position in open_positions
        begin
          max_exit_date = Position.trading_date_from(position.entry_date, days_to_close)
          if max_exit_date > Date.today
            ticker_max = DailyBar.maximum(:bartime, :conditions => { :ticker_id => position.ticker_id } )
            max_exit_date = ticker_max.localtime
          end
          ts = Timeseries.new(position.ticker_id, position.entry_date..max_exit_date, resolution, self.options.merge(:logger => logger))
          exit_time, indicator = ts.instance_exec(closing.params, &closing.block)
          if exit_time.nil?
            Position.close(position, max_exit_date, ts.value_at(max_exit_date, :close), :indicator => indicator, :closed => false)
          else
            Position.close(position, exit_time, ts.value_at(exit_time, :close), :indicator => indicator, :closed => true)
          end
          exit_strategy.positions << position
        rescue TimeseriesException => e
          logger.error("#{e.class.to_s}: #{e.to_s}. DELETING POSITION!")
          position.destroy
        end
        logger.info format("Position %d of %d (%s) %s\t%d\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%s",
                           counter, pos_count, position.ticker.symbol,
                           position.entry_date.to_formatted_s(:ymd),
                           position.days_held, position.entry_price, positioin.exit_price, position.nreturn*100.0,
                           position.roi, position.indicator.name ) if log? :exits
        counter += 1
      end

      endt = Time.now
      delta = endt - startt

      logger.info "Backtest (close positions) elapsed time: #{format_et(delta)}" if log? :basic

      if self.options[:profile]
        GC.disable
        results = RubyProf.stop
        GC.enable

        File.open "#{RAILS_ROOT}/tmp/close-position.prof", 'w' do |file|
          RubyProf::CallTreePrinter.new(results).print(file)
        end
      end
    else
      logger.info "Using pre-computed exits..."
    end
    generate_stats(exit_strategy.positions) if self.options[:generate_stats]

    endt = Time.now
    global_delta = endt - global_startt
    logger.info "Total Backtest elapsed time: #{format_et(global_delta)}" if log? :basic


    #--------------------------------------------------------------------------------------------------------------------
    # Stop-loss pass. The nitty gritty of threshold crossing is handeled by tstop(...)
    #-------------------------------------------------------------------------------------------------------------------
    unless stop_loss.nil? || stop_loss.threshold.to_f == 100.0
      logger.info "Beginning stop loss analysis..."
      startt = Time.now
      open_positions = exit_strategy.positions.find(:all, :conditions => { :scan_id => scan.id })
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
      logger.info "Beginning post processing (make_sheet)..." if log? :basic
      startt = Time.now

      post_process.call(entry_strategy, exit_strategy, scan) if post_process

      endt = Time.now
      delta = endt - startt

      logger.info "Post processing (make_sheet) elapsed time: #{format_et(delta)}" if log? :basic
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
      logger.info "Begining truncate of #{name}..." if log? :basic
      case symbol
      when :trigger_strategy then  trigger_strategy.positions.clear unless (count = trigger_strategy.positions.count).zero?
      when :entry_strategy   then  entry_strategy.positions.clear unless (count = entry_strategy.positions.count).zero?
      when :exit_strategy    then  exit_strategy.positions.clear unless (count = exit_strategy.positaions.count).zero?
      when :scan             then  scan.positions.clear unless (count = scan.positions.count).zero?
      else
        raise ArgumentError, ":truncate must take one or an array of the following: :trigger_strategy, :entry_strategy, :exit_strategy or :scan"
      end
      total_count += count
    end
    delta = Time.now - startt
    logger.info "Truncated #{total_count} positions in #{format_et(delta)}" if log? :basic
  end

  #--------------------------------------------------------------------------------------------------------------------
  # Geerate statistics recorded are given by the params given to the function compute_and_persist
  #--------------------------------------------------------------------------------------------------------------------
  def generate_stats(positions)
    logger.info "Beginning indicator statistics generatian..."
    startt = Time.now
    for position in positions
      start_date = Position.trading_date_from(position.triggered_at, -10)
      end_date = Position.trading_date_from(position.exit_date, 10)
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
    logger.info "Generate Position Statitics took #{format_et(delta)}" if log? :basic
  end

  #--------------------------------------------------------------------------------------------------------------------
  # set the log of the type (not the importance) of the log messages output types are:
  #     basic, entries, exis,
  #--------------------------------------------------------------------------------------------------------------------
  def set_log_level(flags)
    options = %w{ none basic entries exits stops}.map(&:to_sym)
    flags = [flags] unless flags.is_a? Array
    unless flags.all? { |flag| options.member? flag }
      flags.each do |flag|
        unless options.member? flag
          raise ArgumentError, "log level #{flags} is not one of the support options: #{options.join(', ')}"
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
  def format_et(seconds)
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
          days_held = Position.trading_day_count(edate, xdate)
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
