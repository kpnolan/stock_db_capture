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

  def tickers_with_full_history
    sql = "select symbol from daily_closes left outer join tickers on ticker_id = tickers.id  group by ticker_id having min(date) = '20000103' order by symbol"
    DailyClose.connection.select_values(sql)
  end

  def tickers_with_lagging_history
    sql = "select symbol, max(date) from daily_bars left outer join tickers on ticker_id = tickers.id  group by ticker_id having max(date) < '#{latest_date.to_s(:db)}' order by symbol"
    DailyBar.connection.select_rows(sql)
  end

 #    def tickers_with_lagging_history
 #   sql = "select symbol, max(date) from intrday_bars left outer join tickers on ticker_id = tickers.id  group by ticker_id having max(date) < '#{latest_date.to_s(:db)}' order by symbol"
 #   DailyBar.connection.select_rows(sql)
 # end

  def tickers_with_bad_symbols
    sql = "select symbol,min(date),max(date) from daily_closes left outer join tickers on ticker_id = tickers.id where symbol regexp '^[A-Z]*-P[A-Z]+$' group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_no_history
    DailyBar.connection.select_values("SELECT tickers.id FROM tickers LEFT OUTER JOIN daily_bars ON tickers.id = ticker_id WHERE ticker_id IS NULL order by symbol")
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

  def set_inactive_with_no_history
    ids = tickers_with_no_history()
    ids.each do |id|
      ticker = Ticker.find id
      ticker.update_attribute(:active, false)
    end
  end

  def load_dailys_for_year(logger, year)
    symbols = tickers_with_no_history()
    max = symbols.length
    count = 1
    start_date = Date.civil(1999, 1, 1)
    end_date = Date.civil(2009, 6, 5)
    for symbol in symbols
      next if symbol.nil?
      begin
        puts "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        logger.info "loading #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        DailyBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first == '400'
          puts "No data found for #{symbol}"
          logger.info "No data found for #{symbol}"
          ticker = Ticker.find_by_symbol(symbol)
          ticker.increment! :retry_count if ticker
          ticker.toggle! :active if ticker.retry_count == 12
        end
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
      end
      count += 1
    end
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
          ticker.toggle! :active if ticker.retry_count == 12
        end
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
      end
      count += 1
    end
  end

  def load_tda_intraday(symbols)
    count = 1
    max = symbols.length
    end_date = latest_date()
    for symbol in symbols
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
          ticker.toggle! :active if ticker.retry_count == 12
        end
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
      end
      count += 1
    end
  end

  def load_tda_symbols()
    FasterCSV.foreach(File.join(RAILS_ROOT, '..', 'etfs.csv')) do |row|
      symbol, name, sector = row
      if (ticker = Ticker.find_by_name(symbol)) && ticker.symbol.nil?
        sector_id = Sector.find_by_name(sector)
        puts "Creating #{symbol}"
        Ticker.create!(:symbol => symbol, :name => name, :sector_id => sector_id, :industry_id => industry_id, :active => true, :etf => true);
      end
    end
  end
end
