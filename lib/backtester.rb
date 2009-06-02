require 'analytics/maker'
require 'analytics/builder'
require 'population/builder'
require 'population/maker'
require 'backtest/maker'
require 'backtest/builder'
require 'yaml'

require 'rubygems'
require 'ruby-debug'

class BacktestException < Exception
  def initialize(msg)
    super(msg)
  end
end

class Backtester
  attr_accessor :tid_array, :ticker, :date_range, :ts, :result_hash, :meta_data_hash, :strategy, :scan
  attr_reader :pnames, :sname, :desc, :options, :positions, :block

  def initialize(strategy_name, population_names, description, options, &block)
    @options = options.reverse_merge :populate => true, :resolution => 1.day, :plot_results => false
    @sname = strategy_name
    @pnames = population_names
    @desc = description
    @block = block
    @positions = []

    raise BacktestException.new("Cannot find strategy: #{sname.to_s}") if Strategy.find_by_name(sname).nil?

    pnames.each do |pname|
      raise BacktestException.new("Cannot find population: #{pname.to_s}") if Scan.find_by_name(pname).nil?
    end
  end

  def run(logger)
    $logger = logger
    logger.info "Processing backtest of #{sname} against #{pnames.join(', ')}"
    self.strategy = Strategy.find_by_name(sname)
    self.strategy.block = $analytics.find_openning(sname).third
    phash = params(strategy.params_yaml)
    # Loop through all of the populations given for this backtest
    startt = Time.now
    ActiveRecord::Base.benchmark("Open Positions", Logger::INFO) do
      for scan_name in pnames
        self.scan = Scan.find_by_name(scan_name)
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
        self.tid_array = scan.tickers_ids
        sdate = scan.start_date
        edate = scan.end_date
        self.date_range = sdate..edate
        # Foreach ticker in the population, create a timeseries for the date range given with the population
        # and run the analysis given with the strategy on said timeseries
        for tid in tid_array
          self.ticker = Ticker.find tid
          ts = Timeseries.new(ticker.symbol, date_range, options[:resolution], options)
          open_positions(ts, phash)
        end
        strategy.scans << scan
      end

      endt = Time.now
      delta = endt - startt
      deltam = delta/60.0
      logger.info "Open position elapsed time: #{deltam} minutes"
      # Now closes the posisitons that we just openned by running the block associated with the backtest
      # The purpose for "apply" kind of backtest is to open positions based upon the criterion given
      # in the "analytics" section and then close them be evaluating the block associated with the "apply"
      # If everybody does what they're supposed to do, we end up with a set of positions that have been openned
      # and closed, giving the raw data for the analysis of the backtest
      logger.info "Beginning close positions analysis..."
      startt = Time.now
      pos_count = strategy.positions.length
      counter = 1
      ActiveRecord::Base.benchmark("Close Positions", Logger::INFO) do
        for position in strategy.positions
          p = block.call(position)
          if position.exit_price.nil?
            logger.info "Position #{counter} of #{pos_count} #{p.entry_date.to_date}\t>120\t#{p.entry_price}\t***.**\t0.000000"
            else
            logger.info "Position #{counter} of #{pos_count} #{p.entry_date.to_date}\t#{p.days_held}\t#{p.entry_price}\t#{p.exit_price}\t#{p.nreturn*100.0}"
          end
          counter += 1
        end
      end
      endt = Time.now
      delta = endt - startt
      deltam = delta/60.0
      logger.info "Backtest (close positions) elapsed time: #{deltam} minutes"
    end
  end

  # Convert the yaml formatted hash of params back into a hash
  def params(yaml_str)
    @params ||= YAML.load(yaml_str)
  end

  # Run the analysis associated with the strategy which returns a set of indexes for which analysis is true
  # Convert this indexes to dates and open a position on that date at the openning price
  # Remember all of the positions openned for the second part of the backtest, which is to close
  # the open positions
  def open_positions(ts, params)
    begin
      open_indexes = strategy.block.call(ts, params)
      for index in open_indexes
        price = ts.value_at(index, :close)
        date = ts.index2time(index)
        debugger if date.nil?
        entry_trigger = ts.memo.result_for(index)
        #TODO wipe all positions associated with the strategy if the strategy changes
        position = Position.open(scan, strategy, ticker, date, price, entry_trigger)
        @positions << position
        strategy.positions << position
        position
      end
    rescue NoMethodError => e
      logger.info e.message unless e.message =~ /to_v/
    rescue TimeseriesException => e
      logger e.messge unless e.message =~ /recorded history/
    end
  end
end

