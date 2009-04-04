class StrategyEngine
  attr_accessor :tid_array, :ticker, :date_range, :ts, :result_hash, :meta_data_hash

  def initialize(population, date_range, options={})
    options.reverse_merge! :populate => true, :resolution => 1.day, :plot_results => false
    self.tid_array = papulation.ticker_ids
    self.date_range = date_range
    raise ArgumentError.new("invalid symbol: #{symbol.to_s.upcase}") if self.ticker.nil?
  end

  def run()
    for tid in tid_array
      self.ticker = Ticker.find tid
      ts = Timeseries.new(ticker.symbol, date_range, options[:resolution], options)
      log_positions(ts)
    end
  end

  def log_positions(ts)
    for strategy in @@strategies
      srec = Strategy.find_by_name(strategy)
      ticker = Ticker.lookup(ts.symbol)
      open_indexes = strategy.call(ts)
      for opening_index in opening_indexes
        open = ts.value_at(index, :open)
        date = index2dtime(index)
        week = ts.value_at(index, :week)
        Position.log(population, srec, ticker, open, date, week)
      end
    end
  end

end
