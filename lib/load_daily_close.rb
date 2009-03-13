module LoadDailyClose

  attr_accessor :logger

  def tickers_with_no_history
    DailyClose.connection.select_values("SELECT tickers.id FROM tickers LEFT OUTER JOIN daily_closes ON tickers.id = ticker_id WHERE ticker_id IS NULL order by symbol")
  end

  def tickers_with_partial_history
    DailyClose.connection.select_values("select ticker_id from daily_closes LEFT OUTER JOIN tickers ON tickers.id = ticker_id group by ticker_id having active = 1 and max(date) < '#{(Date.today-1).to_s(:db)}' order by symbol")
  end

  def load_history(logger)
    self.logger = logger
    load_empty_history()
  end

  def update_history(logger)
    self.logger = logger
    load_partial_history()
  end

  def load_empty_history()
    min_date = Date.parse('01/01/2000')
    tids = tickers_with_no_history()
    tids.each do |ticker_id|
      ticker = Ticker.transaction do
        ticker = Ticker.find_by_id(ticker_id, :lock => true)
        next if ticker.locked
        ticker.locked = true
        ticker.save!
        ticker
      end
      next if ticker.nil?
      symbol = ticker.symbol
      rows = YahooFinance::get_historical_quotes(symbol, min_date, Date.today, 'd')
      ticker.update_attribute(:active, false) if rows == 0
      logger.info("#{symbol} returned #{rows.length} rows") if logger
      rows.each do |row|
        create_history_row(ticker.id, row)
      end
    end
  end

  def load_partial_history()
    tids = tickers_with_partial_history()
    tids.each do |ticker_id|
      min_date = DailyClose.connection.select_value("SELECT MAX(date) FROM daily_closes WHERE ticker_id = #{ticker_id}")
      min_date = Date.parse(min_date)+1.day
      symbol = Ticker.find_by_id(ticker_id).symbol
      rows = YahooFinance::get_historical_quotes(symbol, min_date, Date.today, 'd')
      logger.info("#{symbol} returned #{rows.length} rows") if logger
      rows.each do |row|
        create_history_row(ticker_id, row)
      end
    end
  end

  def create_history_row(ticker_id, row)
    # The sequence of this array is critical; it has to match the column order of the row returned from Yahoo.
    attrs = [ :date, :open, :high, :low, :close, :volume, :adj_close]
    begin
      ar = DailyClose.new do |ar|
        attrs.each {  |attr| ar[attr] = row.shift }
        ar.ticker_id = ticker_id
        ar.month = ar.date.month
        ar.week = ar.date.cweek
      end
      ar.save!
    rescue ActiveRecord::RecordInvalid => e
      # we arrive here when we have a dup ticker_id/date
      # which is to be expected since we start the history capture
      # from the last (max) date
      logger.error("rejected record: #{ar.inspect}") if logger
      return
    end
  end
end

