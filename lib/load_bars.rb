require 'rubygems'
require 'ruby-debug'
require 'trading_calendar'
require 'faster_csv'

module LoadBars

  MAX_RETRY = 12

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

  def latest_intrday
    Date.parse('05/29/2009')
  end

  def tickers_with_full_history
    sql = "select symbol from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id having min(date) = '20000103' order by symbol"
    DailyClose.connection.select_values(sql)
  end

  def tickers_with_lagging_history
    sql = "select symbol, max(date) from daily_bars left outer join tickers on ticker_id = tickers.id  group by ticker_id having max(date) < '#{latest_date.to_s(:db)}' order by symbol"
    DailyBar.connection.select_rows(sql)
  end

    def tickers_with_lagging_history
    sql = "select symbol, max(date) from intrday_bars left outer join tickers on ticker_id = tickers.id  group by ticker_id having max(date) < '#{latest_date.to_s(:db)}' order by symbol"
    DailyBar.connection.select_rows(sql)
  end

  def tickers_with_bad_symbols
    sql = "select symbol,min(date),max(date) from daily_closes left outer join tickers on ticker_id = tickers.id where symbol regexp '^[A-Z]*-P[A-Z]+$' group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_no_history
    DailyBar.connection.select_rows("select symbol, min(date), max(date) from daily_closes right outer join no_history on no_history.id = ticker_id group by ticker_id")
  end

  def tickers_with_no_intraday
    IntraDayBar.connection.select_values("select symbol from intra_day_bars right outer join tickers on ticker_id = tickers.id where ticker_id is null order by symbol")
  end

  def update_daily_history(logger)
    @logger = logger
    tuples = tickers_with_lagging_history()
    load_tda_dailys(tuples)
  end

  def load_intraday_history(logger)
    @logger = logger
    symbols = tickers_with_no_intraday()
    load_tda_intraday(symbols)
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
        logger.info "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        DailyBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first == '400'
          ticker = Ticker.find_by_symbol(symbol)
          ticker.increment! :retry_count if ticker
          ticker.toggle! :active if ticker.rety_count == 12
        end
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
      end
      count += 1
    end
  end

  def load_tda_intraday(tuples)
    count = 1
    max = tuples.length
    end_date = latest_intrday()
    for tuple in tuples
      next if tuple.nil?
      symbol = tuple
      start_date = end_date - 6.months
      td = trading_days(start_date..end_date).length
      next if td.zero?
      begin
        puts "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        logger.info "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        IntraDayBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first == '400'
          ticker = Ticker.find_by_symbol(symbol)
          ticker.increment! :retry_count if ticker
          ticker.toggle! :active if ticker.rety_count == 12
        end
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
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
