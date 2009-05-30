require 'rubygems'
require 'ruby-debug'
require 'trading_calendar'
require 'faster_csv'

module LoadDailyBars

  include TradingCalendar

  attr_accessor :logger

  def latest_date
    time = Time.now.getlocal
    if time.hour >= 18
      @cur_date ||= time.to_date
    else
      @cur_date ||= time.to_date - 1.day
    end
  end

  def tickers_with_full_history
    sql = "select symbol from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id having min(date) = '20000103' order by symbol"
    DailyClose.connection.select_values(sql)
  end

  def tickers_with_lagging_history
    sql = "select symbol, max(date) from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id having max(date) < #{latest_date} order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_bad_symbols
    sql = "select symbol,min(date),max(date) from daily_closes left outer join tickers on ticker_id = tickers.id where symbol regexp '^[A-Z]*-P[A-Z]+$' group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_no_history
    DailyBar.connection.select_rows("select symbol, min(date), max(date) from daily_closes right outer join no_history on no_history.id = ticker_id group by ticker_id")
  end

  def update_daily_history(logger)
    @logger = logger
    tuples = tickers_lagging_history()
    load_tda_dailys(tuples)
  end

  def load_tda_dailys(tuples)
    max = tuples.length
    count = 1
    end_date = latest_date()
    for tuple in tuples
      symbol, max_date = tuple
      start_date = Date.parse(max_date) + 1.day
      td = trading_days(start_date..end_date).length
      next if td.zero?
      begin
        puts "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        DailyBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first = '400'

        end
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

  def load_tda_symbols(logger)
    @looger = logger
    FasterCSV.foreach(File.join(RAILS_ROOT, '..', 'etfs.csv')) do |row|
      industry_id = Industry.find_by_name('etf')
      symbol, name, sector = row
      puts symbol
      if (ticker = Ticker.find_by_symbol(symbol))
        sector_id = Sector.find_by_name(sector)
        ticker.update_attributes!(:active => true, :etf => true,
                                  :name => name, :sector_id => sector_id, :industry_id => industry_id)
        @logger.info("updated #{symbol}")
      else
        sector_id = Sector.find_by_name(sector)
        Ticker.create!(:active => true, :etf => true,
                       :name => name, :sector_id => sector_id, :industry_id => industry_id)
        @logger.info("created #{symbol}")
      end
    end
  end
end
