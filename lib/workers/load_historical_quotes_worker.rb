class LoadHistoricalQuotesWorker < BackgrounDRb::Rails

  def do_work(args)
    end_date = args[:end_date]
    @wary = args[:worker_array]
    @length = @wary.length
    @index = 0
    ActiveRecord::Base.silence do
      @wary.each do |tuple|
        tid = tuple.first.to_i
        symbol = tuple.second
        max_date = Date.parse(tuple.third)
        rows = YahooFinance::get_historical_quotes(symbol, max_date+1.day, end_date, 'd')
        @logger.info("#{symbol} returned #{rows.length}")
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
