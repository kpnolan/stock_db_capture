# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'analytics/maker'
require 'analytics/builder'
require 'population/builder'
require 'population/maker'
require 'backtest/maker'
require 'backtest/builder'
require 'strategies/base'
require 'yaml'

require 'rubygems'
require 'ruby-debug'

class BacktestException < Exception
  def initialize(msg)
    super(msg)
  end
end

class Backtester

  attr_accessor :ticker, :ts, :result_hash, :meta_data_hash
  attr_reader :pnames, :sname, :desc, :options, :post_process, :days_to_close, :entry_cache, :ts_cache
  attr_reader :strategy, :opening, :closing, :scan, :stop_loss, :tid_array, :date_range
  attr_reader :resolution, :logger

  def initialize(strategy_name, population_names, description, options, &block)
    @options = options.reverse_merge :resolution => 1.day, :plot_results => false,
                                     :days_to_close => 30, :epass => 0..2, :reset => true
    @sname = strategy_name
    @pnames = population_names
    @desc = description
    @days_to_close = @options[:days_to_close]
    @positions = []
    @post_process = block
    @entry_cache = {}
    @ts_cache = {}
    @resolution = self.options.delete :resolution

    raise BacktestException.new("Cannot find strategy: #{sname.to_s}") unless $analytics.has_pair?(sname)

    pnames.each do |pname|
      raise BacktestException.new("Cannot find population: #{pname.to_s}") if Scan.find_by_name(pname).nil?
    end
  end

  def run(logger)
    @logger = logger
    logger.info "\nProcessing backtest of #{sname} against #{pnames.join(', ')}"
    @strategy = Strategy.find_by_name(sname)
    @opening = $analytics.find_opening(sname)
    @closing = $analytics.find_closing(sname)
    @stop_loss = $analytics.find_stop_loss
    # Loop through all of the populations given for this backtest
    startt = Time.now
    for scan_name in pnames
      @scan = Scan.find_by_name(scan_name)
      # FIXME when a backtest specifies a different set of options, e.g. (:price => :close) we should
      # FIXME invalidate any cached posistions (including and exspecially scans_strategies because the positions will have
      # FIXME totally different values
      if strategy.scan_ids.include?(scan.id)
        #TODO wipe all the scans associated with this position if position changed
        logger.info "Using CACHED positions"
        next
      else
        logger.info "Recomputing Positions"
      end
      @tid_array = scan.tickers_ids
      sdate = options[:start_date] ? options[:start_date] : scan.start_date
      edate = options[:end_date] ? options[:end_date] : scan.end_date
      @date_range = sdate..edate
      # Foreach ticker in the population, create a timeseries for the date range given with the population
      # and run the analysis given with the strategy on said timeseries
      for pass in options[:epass]
        pass_count = 0
        for tid in tid_array
          @ticker = Ticker.find tid
          begin
            if ts_cache[tid].nil?
              ts = Timeseries.new(ticker.symbol, date_range, resolution, options)
              ts_cache[tid] = ts
            elsif ts_cache[tid]
              ts = ts_cache[tid]
            end
          rescue TimeseriesException => e
            logger.error("#{ticker.symbol} has missing dates beteen #{ts.begin_time} and #{ts.end_time}, skipping...")
            logger.error("Error: #{e.to_s}")
            ts_cache[tid] = false
            next
          end
          @entry_cache[tid] ||= []
          pass_count += open_positions(ts, opening.params, pass)
        end
        logger.info(">>>>> Entries for pass #{pass}: #{pass_count} <<<<<<<<<<<<<<<<")
      end
      @entry_cache = nil                # free up to be grabage collected
      strategy.scans << scan
    end
    endt = Time.now
    delta = endt - startt
    deltam = delta/60.0
    logger.info "Open position elapsed time: #{deltam} minutes"
    # Now closes the posisitons that we just opened by running the block associated with the backtest
    # The purpose for "apply" kind of backtest is to open positions based upon the criterion given
    # in the "analytics" section and then close them be evaluating the block associated with the "apply"
    # If everybody does what they're supposed to do, we end up with a set of positions that have been opened
    # and closed, giving the raw data for the analysis of the backtest
    logger.info "Beginning close positions analysis..."
    startt = Time.now

    if options[:reset]
      open_positions = strategy.positions.find(:all)
    else
      open_positions = strategy.positions.find(:all, :conditions => 'exit_date is null')
    end
    pos_count = open_positions.length

    counter = 1
    for position in open_positions
      p = close_position(position)
      next if p.nil?
      if p.exit_date.nil?
        logger.info format("Position %d of %d %s\t>30\t%3.2f\t???.??\t???.??\t???.??", counter, pos_count, p.entry_date.to_s(:short), p.entry_price)
      else
        logger.info format("Position %d of %d %s\t%d\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%s", counter, pos_count, p.entry_date.to_s(:short), p.days_held, p.entry_price, p.exit_price, p.nreturn*100.0, p.return, p.indicator.name )
      end
      counter += 1
    end
    endt = Time.now
    delta = endt - startt
    deltam = delta/60.0
    logger.info "Backtest (close positions) elapsed time: #{deltam} minutes"
    #
    # Perform stop loss analysis if it was specified in the analytics section of the backtest config
    #
    unless stop_loss.nil? || stop_loss.threshold.to_f == 100.0
      logger.info "Beginning stop loss analysis..."
      startt = Time.now
      open_positions = strategy.positions.find(:all)
      open_positions.each do |p|
        tstop(p, stop_loss.threshold, stop_loss.options)
      end
      endt = Time.now
      delta = endt - startt
      deltam = delta/60.0
      logger.info "Backtest (stop loss analysys) elapsed time: #{deltam} minutes"
    end
    #
    # Call any post processing block specified
    #
    post_process.call if post_process
  end
  # Run the analysis associated with the strategy which returns a set of indexes for which analysis is true
  # Convert this indexes to dates and open a position on that date at the openning price
  # Remember all of the positions opened for the second part of the backtest, which is to close
  # the open positions
  def open_positions(ts, params, pass)
      pass_count = 0
      #begin
        open_indexes = ts.instance_exec(params, pass, &opening.block)
        for idx in open_indexes
          aux = { }
          index = case idx
                  when Numeric : idx
                  when Hash : aux = idx; idx[:index]
                  end
          next if index.nil? || @entry_cache[ts.ticker_id].include?(index) # don't enter the same entry twice
          begin
            price = ts.value_at(index, :close)
            time = ts.index2time(index)
            debugger if time.nil?
            entry_trigger = ts.memo.result_for(index)
          rescue Exception => e
            debugger
            puts e.to_s
            next
          end
          #TODO wipe all positions associated with the strategy if the strategy changes
          position = Position.open(scan, strategy, ticker, time, price, entry_trigger, params[:short], pass, aux)
          @entry_cache[ts.ticker_id] << index
          strategy.positions << position
          pass_count += 1
          position
        end
      #rescue NoMethodError => e
      #  logger.info e.message unless e.message =~ /to_v/ or logger.nil?
      #rescue TimeseriesException => e
      #  logger.info e.message unless e.message =~ /recorded history/ or logger.nil?
#      rescue Exception => e
#        logger.info e.message
#        logger.info e.backtrace
    #end
    pass_count
  end

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
      edate = trading_days_from(etime.to_date, 1).last
    end
    max_date = p.exit_date.nil? ? trading_days_from(edate, options[:max_days]).last : p.exit_date.to_date
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
                              ts.symbol, p.entry_price, max_high, low, 100*rratio, ret*100.0))
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

  # Close a position opened during the first phase of the backtest
  def close_position(p)
    begin
      options = self.options.reverse_merge :post_buffer => 0, :debug => true
      end_date = trading_days_from(p.entry_date, days_to_close).last
      ts = Timeseries.new(p.ticker_id, p.entry_date.to_date..end_date, resolution, options)

      result = ts.instance_exec(closing.params, &closing.block)

      indicator, xtime, index = nil, nil, nil

      case result
      when Array      : xtime, indicator = result
      when Numeric    : index = result
      end

      if index.nil? && xtime.nil?
        days_held = days_to_close
        edate = p.entry_date.to_date
        xdate = trading_days_from(edate, days_held).last
        xprice = ts.value_at(ts.index_range.begin+days_held, :close)
        roi = (xprice - p.entry_price) / p.entry_price
        rreturn = xprice/p.entry_price
        logr = Math.log(rreturn.zero? ? 0 : rreturn)
        nreturn = roi / days_held
        p.update_attributes!(:exit_date => xdate, :exit_price => xprice, :roi => roi, #leave out closes so it defaults to NULL
                             :days_held => days_to_close, :nreturn => nreturn, :indicator_id => Indicator.lookup(:unknown).id)
        ts.persist(p, :macd_hist, :rsi, :rvi)
      else
        xprice = index ? ts.value_at(index, :close) : ts.value_at(ts.time2index(xtime), :close)
        edate = p.entry_date.to_date
        xdate = xtime ? xtime.to_date : ts.index2time(index)
        debugger if xdate.nil?
        days_held = Position.trading_days_between(edate, xdate)
        roi = (xprice - p.entry_price) / p.entry_price
        rreturn = xprice/p.entry_price
        logr = Math.log(rreturn.zero? ? 0 : rreturn)
        nreturn = days_held.zero? ? 0.0 : roi / days_held
        nreturn *= -1.0 if p.short and nreturn != 0.0
        indicator_id = Indicator.lookup(indicator).id
        p.update_attributes!(:exit_price => xprice, :exit_date => xdate, :closed => true, :roi => roi,
                             :days_held => days_held, :nreturn => nreturn, :indicator_id => indicator_id)
      end
    rescue TimeseriesException => e
        logger.error("#{e.class.to_s}: #{e.to_s}")
    end
    # rescue ActiveRecord::RecordNotFound
#       indicator = :unknown and retry
#     rescue Exception => e
#       logger.error "#{e.to_s} deleting position}" if logger
#       logger.error p.inspect if logger
#       p.strategies.delete_all
#       p.delete
#       p = nil
#     end
    p
  end
end
