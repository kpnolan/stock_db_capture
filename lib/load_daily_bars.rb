require 'rubygems'
require 'ruby-debug'

module LoadDailyBars

  attr_accessor :logger

  def tickers_with_full_history
    sql = "select symbol from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id having min(date) = '20000103' order by symbol"
    DailyClose.connection.select_values(sql)
  end

  def tickers_with_partial_history
    sql = "select symbol,min(date) from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_bad_symbols
    sql = "select symbol,min(date),max(date) from daily_closes left outer join tickers on ticker_id = tickers.id where symbol regexp '^[A-Z]*-P[A-Z]+$' group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_no_history
    DailyBar.connection.select_rows("select symbol, min(date), max(date) from daily_closes right outer join no_history on no_history.id = ticker_id group by ticker_id")
  end

  def load_tda_history(logger)
    @logger = logger
    tuples = tickers_with_no_history()
    load_tda_dailys(tuples)
  end

  def load_tda_dailys(tuples)
    max = tuples.length
    count = 1
    for tuple in tuples
      symbol, start_date, end_date = tuple
      begin
        puts "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        DailyBar.load_tda_history(symbol, start_date, end_date)
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
        next
      ensure
        count += 1
      end
      count += 1
    end
  end
end
