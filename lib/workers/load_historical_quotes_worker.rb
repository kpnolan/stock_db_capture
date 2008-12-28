class LoadHistoricalQuotesWorker < BackgrounDRb::Rails

  def do_work(args)
    start_date = args[:start_date]
    end_date = args[:end_date]
    symbols = args[:symbols]
    @length = symbols.length
    @index = 0
    ActiveRecord::Base.silence do
      symbols.each do |symbol|
        tid = Ticker.find_by_symbol(symbol).id
        rows = YahooFinance::get_historical_quotes(symbol, start_date, end_date, 'd')
        @logger.info("#{symbol} returned #{rows.length} rows")
        rows.each do |row|
          create_history_row(tid, row)
        end
      end
      @index += 1
    end
  end

  def progress
    @index.to_f/@length.to_f
  end

  private

  def create_history_row(ticker_id, row)
    # The sequence of this array is critical; it has to match the column order of the row returned from Yahoo.
    attrs = [ :date, :open, :high, :low, :close, :volume, :adj_close]
    DailyClose.new do |ar|
      attrs.each {  |attr| ar[attr] = row.shift }
      ar.ticker_id = ticker_id
      ar.month = ar.date.month
      ar.week = ar.date.cweek
    end.save!
  end
end
