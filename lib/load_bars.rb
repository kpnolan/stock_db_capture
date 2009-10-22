# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'ruby-debug'
require 'trading_calendar'
require 'faster_csv'
require 'holidays' # rake doesn't load on demand files with indefined constants so this has to be explicitly loaded
require 'rational'

module LoadBars

  MAX_RETRY = 12

  extend TradingCalendar

  attr_accessor :logger

  def latest_date
    time = Time.now.getlocal
    if time.hour >= 23
      @cur_date ||= time.to_date
    else
      @cur_date ||= time.to_date - 1.day
    end
  end

  def tickers_from_yahoo()
    sql = "select ticker_id, bartime from daily_bars left outer join tickers on tickers.id = ticker_id where adj_close is not null and volume <> 0 group by ticker_id order by symbol"
    DailyBar.connection.select_rows(sql)
  end

  def daily_bars_with_zero_volume()
    sql = "select ticker_id, bartime from daily_bars left outer join tickers on tickers.id = ticker_id where adj_close is not null and volume = 0 group by ticker_id order by symbol"
    DailyBar.connection.select_rows(sql)
  end

  def tickers_with_some_history
    sql = "select ticker_id from daily_bars left outer join tickers on tickers.id = ticker_id  group by ticker_id order by symbol"
    DailyBar.connection.select_values(sql)
  end

  def missing_bars(table1, table2)
    sql = "select a.id from #{table1} a left outer join #{table2} b using(ticker_id, bartime) join tickers on tickers.id = a.ticker_id where b.bartime is null order by symbol, a.bartime"
    DailyBar.connection.select_values(sql)
  end

  def zero_volume_missing_bars(table1, table2)
    sql = "select a.id from #{table1} a left outer join #{table2} b using(ticker_id, bardate) join tickers on tickers.id = a.ticker_id where a.volume = 0 and b.bardate is null order by symbol, a.bardate"
    DailyBar.connection.select_values(sql)
  end

  def tickers_with_lagging_history(table)
    sql = "select symbol, max(date(bartime)) from #{table} left outer join tickers on tickers.id = ticker_id  group by ticker_id having max(date(bartime)) < '#{latest_date.to_s(:db)}' order by symbol"
    DailyBar.connection.select_rows(sql)
  end

  def tickers_with_lagging_intraday
    sql = "select symbol, max(date(bartime)) from intra_day_bars left outer join tickers on tickers.id = ticker_id where active = 1 group by ticker_id having max(date(bartime)) < '#{latest_date.to_s(:db)}' order by symbol"
    @logger.info("SQL: #{sql}")
    DailyBar.connection.select_rows(sql)
  end

  def tickers_with_bad_symbols
    sql = "select symbol,min(date),max(date) from daily_bars left outer join tickers on tickers.id = tickers_id where symbol regexp '^[A-Z]*-P[A-Z]+$' group by ticker_id order by symbol"
    DailyClose.connection.select_rows(sql)
  end

  def tickers_with_no_history(table='daily_bars')
    DailyBar.connection.select_values("SELECT tickers.id FROM tickers LEFT OUTER JOIN #{table} ON tickers.id = ticker_id WHERE ticker_id IS NULL order by symbol").map(&:to_i)
  end

  def tickers_with_no_intraday
    dir = ENV['INTRA_DAY'] == '2' ? 'DESC' : ''
    IntraDayBar.connection.select_values("select symbol from intra_day_bars right outer join tickers on tickers.id = ticker_id where ticker_id is null and active = 1 order by symbol #{dir}")
  end

  def nearest_join(ticker_id, date, table, direction)
    case table
      when 'yahoo_bars'  : b_close = 'b.adj_close'
      when 'google_bars' : b_close = 'b.close'
    end
    case direction
      when -1 : relop, sort = '<', 'desc'
      when  1 : relop, sort = '>', 'asc'
    else
      raise ArgumentError, "direction must be -1 or 1"
    end
    sql = "select a.bardate, a.close, #{b_close}, b.volume from daily_bars a join #{table} b using(ticker_id, bardate) where a.ticker_id = #{ticker_id} and a.bardate #{relop} '#{date.to_s(:db)}' order by a.bardate #{sort} limit 1"
    values = DailyBar.connection.select_rows(sql)
    if values.empty?
      return nil, nil, nil, -1
    else
      date, close, adj_close, volume = values.first
      return Date.parse(date), close.to_f, adj_close.to_f, volume.to_i
    end
  end

  def generate_intra_close_report()
     sql = "select symbol, year(daily_bars.bartime) as year, month(daily_bars.bartime) as month, avg(daily_bars.close) as avg_close, " +
           "avg(intra_day_bars.close) as avg_3_30_close, avg((daily_bars.close-intra_day_bars.close)/daily_bars.close) as avg_3_30_ratio "+
           "from daily_bars, intra_day_bars, tickers "+
           "where tickers.id = daily_bars.ticker_id and daily_bars.ticker_id = intra_day_bars.ticker_id and "+
           "date(intra_day_bars.bartime) = date(daily_bars.bartime) and date(daily_bars.bartime) and (time(intra_day_bars.bartime) = '20:00:00' "+
           "or time(intra_day_bars.bartime) = '19:00:00') group by daily_bars.ticker_id, year(daily_bars.bartime), month(daily_bars.bartime) "+
           "order by year(daily_bars.bartime), month(daily_bars.bartime), symbol into outfile '/tmp/delta_close4.tsv'"
    DailyBar.connection.execute(sql)
  end

  def update_daily_history(logger)
    @logger = logger
    tuples = tickers_with_lagging_history('daily_bars')
    load_tda_dailys(tuples)
  end

  def update_intraday_history(logger)
    @logger = logger
    tuples = tickers_with_lagging_intraday()
    load_tda_intraday(tuples)
  end

  def load_intraday_history(logger)
    @logger = logger
    symbols = tickers_with_no_intraday()
    load_tda_intraday(symbols)
  end

  def set_inactive_with_no_history
    ids = tickers_with_no_history('daily_bars')
    ids.each do |id|
      ticker = Ticker.find id
      ticker.update_attribute(:active, false)
    end
  end

  def load_splits(logger, proc_id, proc_cnt)
    ticker_ids = Ticker.find(:all, :conditions => "symbol not like '%-%'").map(&:id)
    chunk_size = ticker_ids.length / proc_cnt
    chunk_start = proc_id * chunk_size
    chunk_end = ((proc_id == proc_cnt - 1) ? ticker_ids.length - 1 : chunk_start + chunk_size - 1)
    count = 0
    for i in (chunk_start..chunk_end) do
      ticker_id = ticker_ids[i]
      ticker = Ticker.find ticker_id
      symbol = ticker.symbol
      next if symbol.include? '-'
      cnt = Split.load_from_symbol(symbol)
      logger.info "(#{proc_id}) loaded #{cnt} splits for #{symbol}\t#{count} of #{chunk_size}" unless cnt.zero?
      count += 1
    end
  end

  def load_yahoo_bars(logger, proc_id, proc_cnt)
    qs = YahooFinance::QuoteServer.new()
    ticker_ids = tickers_with_no_history('yahoo_bars')
    chunk_size = ticker_ids.length / proc_cnt
    chunk_start = proc_id * chunk_size
    chunk_end = ((proc_id == proc_cnt - 1) ? ticker_ids.length - 1 : chunk_start + chunk_size - 1)
    count = 0
    min_date = Date.parse('1999-1-1')
    max_date = Date.parse('2009-10-9')
    for i in (chunk_start..chunk_end) do
      ticker_id = ticker_ids[i]
      ticker = Ticker.find ticker_id
      symbol = ticker.symbol
      next if symbol.include? '-'
      bars = qs.dailys_for(symbol, min_date, max_date)
      logger.info "(#{proc_id}) loading #{symbol}\t#{min_date}\t#{max_date}\t#{bars.length}\tbars\t#{count} of #{chunk_size}"
      bars.each { |bar| YahooBar.create_bar(symbol, ticker_id, bar) }
      count += 1
    end
  end

  def load_google_bars(logger, proc_id, proc_cnt)
    qs = GoogleFinance::QuoteServer.new(:logger => logger)
    ticker_ids = tickers_with_no_history('google_bars')
    chunk_size = ticker_ids.length / proc_cnt
    chunk_start = proc_id * chunk_size
    chunk_end = ((proc_id == proc_cnt - 1) ? ticker_ids.length - 1 : chunk_start + chunk_size - 1)
    count = 0
    min_date = Date.parse('1999-1-1')
    max_date = Date.parse('2009-10-16')
    for i in (chunk_start..chunk_end) do
      ticker_id = ticker_ids[i]
      ticker = Ticker.find ticker_id
      symbol = ticker.symbol
      count += 1
      next if symbol.include? '-'
      bars = qs.dailys_for(symbol, min_date, max_date)
      logger.info "(#{proc_id}) loading #{symbol}\t#{min_date}\t#{max_date}\t#{bars.length}\tbars\t#{count} of #{chunk_size}"
      bars.each { |bar| GoogleBar.create_bar(symbol, ticker_id, bar) }
    end
  end

  def update_yahoo_bars(logger, proc_id, proc_cnt)
    qs = YahooFinance::QuoteServer.new()
    tuples = tickers_with_lagging_history('yahoo_bars')
    end_date = latest_date()
    chunk_size = tuples.length / proc_cnt
    chunk_start = proc_id * chunk_size
    chunk_end = ((proc_id == proc_cnt - 1) ? tuples.length - 1 : chunk_start + chunk_size - 1)
    count = 0
    for i in (chunk_start..chunk_end) do
      symbol, max_date = tuples[i]
      next if symbol.include? '-'
      max_date = Date.parse(max_date)
      start_date = max_date + 1.day
      td = trading_day_count(start_date, end_date)
      next if td.zero?
      ticker = Ticker.lookup(symbol)
      bars = qs.dailys_for(symbol, start_date, end_date)
      logger.info "(#{proc_id}) loading #{symbol}\t#{start_date}\t#{end_date}\t#{bars.length}\tbars\t#{count} of #{chunk_size}"
      bars.each { |bar| YahooBar.create_bar(symbol, ticker.id, bar) }
      count += 1
    end
  end

  def load_all_dailys(logger, proc_id, proc_cnt)
    @logger = logger
    ticker_ids = tickers_with_no_history('daily_bars')
    max = ticker_ids.length
    start_date = Date.civil(1999, 1, 1)
    end_date = latest_date()
    chunk_size = ticker_ids.length / proc_cnt
    chunk_start = proc_id * chunk_size
    chunk_end = ((proc_id == proc_cnt - 1) ? ticker_ids.length - 1 : chunk_start + chunk_size - 1)
    count = 0
    for i in (chunk_start..chunk_end) do
      ticker_id = ticker_ids[i]
      ticker = Ticker.find(ticker_id)
      symbol = ticker.symbol
      next if symbol.nil?
      begin
        @logger.info "(#{proc_id}) loading #{symbol}\t#{count} of #{chunk_size}"
        DailyBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first == '400'
          logger.info "No data found for #{symbol}"
          ticker.increment! :retry_count if ticker
          ticker.toggle! :active if ticker.retry_count == 12
        end
      rescue Exception => e
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
      end
      count += 1
    end
  end

  def fill_missing_bars(logger, proc_id, proc_cnt)
    columns = GoogleBar.columns.map(&:name).map(&:to_sym)
    columns.delete :id
    inserted_bars = 0
    rejected_bars = 0
    count = 0
    ticker_ids = tickers_with_some_history().map!(&:to_i)
    chunk = Splitter.new(proc_id, proc_cnt, ticker_ids)
    for ticker_id in chunk
      symbol = Ticker.find(ticker_id).symbol
      count += 1
      row_cnt = 0
      next if symbol.include?('-')
      min_date = DailyBar.minimum(:bardate, :conditions => { :ticker_id => ticker_id })
      max_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
      ts = Timeseries.new(ticker_id, min_date..max_date, 1.day, :populate => true, :missing_bar_error => :ignore)
      next if ts.missing_ranges.empty?
      for date_range in ts.missing_ranges()
        start_date, end_date = date_range.begin.to_date, date_range.end.to_date
        day_count = trading_day_count(date_range.begin, date_range.end)
        before_date, before_close, before_adj_close, ignore = nearest_join(ticker_id, start_date, 'google_bars', -1)
        after_date, after_close, after_adj_close, ignore = nearest_join(ticker_id, end_date, 'google_bars', 1)
        before_gap = before_date ? trading_day_count(before_date, start_date, false) : -1
        after_gap = after_date ? trading_day_count(end_date, after_date, false) : -1
        if before_gap == 1 && after_gap == 1 && (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01
          rows = GoogleBar.all(:conditions => { :ticker_id => ticker_id, :bardate => start_date..end_date }, :order => 'bardate')
          for row in rows
            attrs = columns.inject({}) { |h, k| h[k] = row[k]; h }
            attrs[:source] = 'G'
            begin
              DailyBar.create! attrs
              inserted_bars += 1
              row_cnt += 1
            rescue Exception => e
              logger.error e.to_s
              logger.error "Bad Row: #{row.inspect}"
              rejected_bars += 1
            end
          end
        end
      end
      logger.info "(#{proc_id}) #{symbol}\tinserted #{row_cnt} bars\t#{count} of #{chunk.length}"
    end
    logger.info "Inserted Bars: #{inserted_bars} Rejected Bars: #{rejected_bars}"
    logger.close
  end

  def report_missing_bars(logger, proc_id, proc_cnt)
    source = 'google'
    model = (source.capitalize + 'Bar').constantize
    FasterCSV.open(File.join(RAILS_ROOT, 'log', 'missing_bars.csv'), "w+") do |csv|
      csv << ['Symbol', 'Range Begin', 'Range End', 'Trading Days', 'TDA Close Before', 'AdjClose Before', 'TDA Close After', 'Adj Close After', 'Sync Date Before', 'Sync Date After', 'Before Gap', 'After Gap', 'Max Vol', 'Replacce Bar Count', 'Eligible']
      cnt = 0
      ticker_ids = tickers_with_some_history().map!(&:to_i)
      chunk = Splitter.new(proc_id, proc_cnt, ticker_ids)
      for ticker_id in chunk
        cnt += 1
        symbol = Ticker.find(ticker_id).symbol
        next if symbol.include?('-')
        min_date = DailyBar.minimum(:bardate, :conditions => { :ticker_id => ticker_id })
        max_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
        ts = Timeseries.new(ticker_id, min_date..max_date, 1.day, :populate => true, :missing_bar_error => :ignore)
        next if ts.missing_ranges.empty?
        for date_range in ts.missing_ranges()
          start_date, end_date = date_range.begin.to_date, date_range.end.to_date
          day_count = trading_day_count(date_range.begin, date_range.end)
          before_date, before_close, before_adj_close, before_volume = nearest_join(ticker_id, start_date, source + '_bars', -1)
          after_date, after_close, after_adj_close, after_volume = nearest_join(ticker_id, end_date, source + '_bars', 1)
          before_gap = before_date ? trading_day_count(before_date, start_date, false) : -1
          after_gap = after_date ? trading_day_count(end_date, after_date, false) : -1
          ycount = model.count(:conditions => { :ticker_id => ticker_id, :bardate => start_date..end_date })
          vol = [before_volume, after_volume].max
          flag = (before_gap == 1 && after_gap == 1 && (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01) ? '***' : ''
          row = [ts.symbol, date_range.begin.to_date, date_range.end.to_date, day_count, before_close, before_adj_close, after_close, after_adj_close, before_date, after_date, before_gap, after_gap, vol, ycount, flag].map{ |el| el.nil? ? false : el }
          csv << row
          logger.info "(#{proc_id}) #{symbol}\t#{cnt} of #{chunk.length}"
        end
      end
    end
  end

  def compute_in_memory
    total_days = 0
    eligible_days = 0
    FasterCSV.foreach(File.join(RAILS_ROOT, 'log', 'compact_missing_bars.csv')) do |row|
      symbol, date_begin, date_end, day_count, before_close, before_adj_close, after_close, after_adj_close, before_date, after_date, before_gap, after_gap = row
      print "#{symbol} "
      day_count = day_count.to_i
      if before_gap == '1' and after_gap == '1'
        before_close = before_close.to_f
        before_adj_close = before_adj_close.to_f
        after_close = after_close.to_f
        after_adj_close = after_adj_close.to_f
        eligible_days += day_count if (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01
      end
      total_days += day_count
    end
    puts "eligible days: #{eligible_days}"
    puts "total days: #{total_days}"
  end

  def compute_eligable_bars()
    ticker_ids = tickers_with_some_history()
    @total_days = 1
    @eligible_days = 1
    for ticker_id in ticker_ids.map!(&:to_i)
      symbol = Ticker.find(ticker_id).symbol
      print "#{symbol} "
      min_date = DailyBar.minimum(:bardate, :conditions => { :ticker_id => ticker_id })
      max_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id })
      ts = Timeseries.new(ticker_id, min_date..max_date, 1.day, :populate => true, :missing_bar_error => :ignore)
      next if ts.missing_ranges.empty?
      for date_range in ts.missing_ranges()
        day_count = trading_day_count(date_range.begin, date_range.end)
        before_date, before_close, before_adj_close = before_join(ticker_id, date_range.begin.to_date)
        after_date, after_close, after_adj_close = after_join(ticker_id, date_range.end.to_date)
        before_gap = before_date ? trading_day_count(before_date, date_range.begin.to_date, false) : nil
        after_gap = after_date ? trading_day_count(date_range.end.to_date, after_date, false) : nil
        if before_gap == 1 && after_gap == 1 && (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01
          @eligible_days += day_count
        end
        @total_days += day_count
      end
    end
    puts ""
    puts "eligible days: #{@eligible_days}"
    puts "total days: #{@total_days}"
  end


  def load_tda_dailys(tuples)
    max = tuples.length
    count = 1
    end_date = latest_date()
    for tuple in tuples
      symbol, max_date = tuple
      max_date = max_date.to_date
      td = trading_day_count(max_date, end_date)
      next if td.zero?
      start_date = max_date + 1.day
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

  def backfill_seq()
    sql = "select id, bartime from intra_day_bars where seq is null"
    rows = IntraDayBar.connection.select_rows(sql)
    basis = 52200
    count = 0
    rows.each do |row|
      id, time = row.first.to_i, Timeseries.parse_time(row.last, "%Y-%m-%d %H:%M:%S" )
      d = (time - time.midnight).to_i
      d = d - basis
      seq = d / (30*60)
      IntraDayBar.connection.execute("update intra_day_bars set seq  = #{seq} where id = #{id}")
      count += 1
    end
    count
  end

  def load_tda_intraday(tuples)
    count = 1
    max = tuples.length
    end_date = latest_date()
    for tuple in tuples
      symbol, max_date = tuple
      max_date = max_date.to_date
      td = trading_day_count(max_date, end_date)
      next if td.zero?
      start_date = max_date + 1.day
      begin
        puts "updating #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        logger.info "updating #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{max}"
        IntraDayBar.load_tda_history(symbol, start_date, end_date)
      rescue Net::HTTPServerException => e
        if e.to_s.split.first == '400'
          ticker = Ticker.find_by_symbol(symbol)
          ticker.increment! :retry_count if ticker
          ticker.toggle! :active if ticker.retry_count == 12
        end
      rescue ActiveRecord::StatementInvalid => e
        puts "Duplicate symbol/time #{symbol} skipping..."
        @logger.error("Duplicate symbol/time #{symbol} skipping...")
      rescue Exception => e
        puts "#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}"
        @logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
        exit
      end
      count += 1
    end
  end

  def load_tda_symbols()
    FasterCSV.foreach(File.join(RAILS_ROOT, '..', 'etfs.csv')) do |row|
      symbol, name, sector = row.map { |str| str.delete('"') }
      if (ticker = Ticker.find_by_symbol(symbol)).nil?
        puts "Symbol: #{symbol} not found"
      else
        sector_id = Sector.find_by_name(sector).id
        ticker.update_attributes!(:sector_id => sector_id);
      end
    end
  end

  class Splitter
    attr_reader :len, :chunk_size, :chunk_start, :chunk_end, :sub_array
    def initialize(id, count, id_array)
      @len = id_array.length
      @chunk_size = len / count
      @chunk_start = id * chunk_size
      @chunk_end = ((id == count - 1) ? len - 1 : chunk_start + chunk_size - 1)
      @sub_array = id_array[chunk_start..chunk_end]
    end

    def length()
      sub_array.length
    end

    def each()
      sub_array.each { |id| yield id }
    end
  end
end
