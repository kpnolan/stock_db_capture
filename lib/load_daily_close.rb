module LoadDailyClose

  attr_accessor :logger

  def tickers_with_no_history
    DailyClose.connection.select_values("SELECT tickers.id FROM tickers LEFT OUTER JOIN daily_closes ON tickers.id = ticker_id WHERE ticker_id IS NULL")
  end

  def tickers_with_partial_history
    DailyClose.connection.select_values("select ticker_id from daily_closes group by ticker_id having max(date) < '#{(Date.today-1).to_s(:db)}'")
  end

  def update_history(logger)
    logger = logger
    load_empty_history()
    load_partial_history()
  end

  def load_empty_history()
    tids = tickers_with_no_history()
    min_date = DailyClose.connection.select_value("select min(date) from daily_closes").to_date
    tids.each do |ticker_id|
      symbol = Ticker.find_by_id(ticker_id).symbol
      rows = YahooFinance::get_historical_quotes(symbol, min_date, Date.today, 'd')
      Ticker.find_by_id(ticker_id).update_attribute(:active => false) if rows == 0
      logger.info("#{symbol} returned #{rows.length} rows") if logger
      rows.each do |row|
        create_history_row(ticker_id, row)
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

