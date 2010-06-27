# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'ruby-debug'
require 'bar_utils'

module LoadBars

  extend BarUtils

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

  def load_TDA(logger);         DailyBar.load(logger);  end
  def update_TDA(logger);       DailyBar.update(logger);  end
  def detect_delisted(logger);  DailyBar.load(logger); end
  def load_yahoo(logger);       YahooBar.load(logger); end
  def update_yahoo(logger);     YahooBar.update(logger); end
  def load_google(logger);      GoogleBar.load(logger);  end
  def update_google(logger);    GoogleBar.update(logger); end
  def update_intraday(logger);  IntraDayBar.update(logger); end
  def forked_update_intraday(logger);  IntraDayBar.forked_update(logger); end
  def load_splits(logger);      Split.load(logger); end

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

  def fill_missing_bars(logger, model, min_date=nil, max_date=nil)
    table = model.to_s.tableize
    columns = model.columns.map(&:name).map(&:to_sym)
    columns.delete :id
    columns.delete :adj_close
    inserted_bars = 0
    rejected_bars = 0
    count = 0
    ticker_ids = tickers_with_some_history().map!(&:to_i)
    chunk = BarUtils::Splitter.new(ticker_ids)
    for ticker_id in chunk
      symbol = Ticker.find(ticker_id).symbol
      count += 1
      row_cnt = 0
      next if symbol.include?('-')
      min_date = DailyBar.minimum(:bardate, :conditions => { :ticker_id => ticker_id }) unless min_date
      max_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id }) unless max_date
      begin
        ts = Timeseries.new(ticker_id, min_date..max_date, 1.day, :populate => true, :missing_bar_error => :ignore)
      rescue Exception => e
        logger.error("#{e.class}: #{e}")
        next
      end
      next if ts.missing_ranges.empty?
      for date_range in ts.missing_ranges()
        start_date, end_date = date_range.begin.to_date, date_range.end.to_date
        day_count = trading_day_count(date_range.begin, date_range.end)
        before_date, before_close, before_adj_close, ignore = nearest_join(ticker_id, start_date, table, -1)
        after_date, after_close, after_adj_close, ignore = nearest_join(ticker_id, end_date, table, 1)
        before_gap = before_date ? trading_day_count(before_date, start_date, false) : -1
        after_gap = after_date ? trading_day_count(end_date, after_date, false) : -1
        if before_gap == 1 && after_gap == 1 && (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01
          rows = model.all(:conditions => { :ticker_id => ticker_id, :bardate => start_date..end_date }, :order => 'bardate')
          puts "filling #{ts.symbol} --\tstart: #{start_date.to_formatted_s(:ymd)}\t#{end_date.to_formatted_s(:ymd)}"
          for row in rows
            attrs = columns.inject({}) { |h, k| h[k] = row[k]; h }
            attrs[:source] = model.source_id
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
      logger.info "(#{chunk.id}) #{symbol}\tinserted #{row_cnt} bars\t#{count} of #{chunk.length}"
    end
    logger.info "Inserted Bars: #{inserted_bars} Rejected Bars: #{rejected_bars}"
  end

  def report_missing_bars(logger, model, min_date=nil, max_date=nil)
    table = model.to_s.tableize
    FasterCSV.open(File.join(RAILS_ROOT, 'log', 'missing_bars.csv'), "w+") do |csv|
      csv << ['Symbol', 'Range Begin', 'Range End', 'Trading Days', 'TDA Close Before', 'AdjClose Before', 'TDA Close After', 'Adj Close After', 'Sync Date Before', 'Sync Date After', 'Before Gap', 'After Gap', 'Max Vol', 'Replacce Bar Count', 'Eligible']
      cnt = 0
      ticker_ids = tickers_with_some_history().map!(&:to_i)
      chunk = BarUtils::Splitter.new(ticker_ids)
      for ticker_id in chunk
        cnt += 1
        symbol = Ticker.find(ticker_id).symbol
        next if symbol.include?('-')
        min_date = DailyBar.minimum(:bardate, :conditions => { :ticker_id => ticker_id }) unless min_date
        max_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => ticker_id }) unless max_date
        begin
          ts = Timeseries.new(ticker_id, min_date..max_date, 1.day, :populate => true, :missing_bar_error => :ignore)
        rescue Exception => e
          logger.error("#{e.class}: #{e}")
          next
        end
        next if ts.missing_ranges.empty?
        for date_range in ts.missing_ranges()
          start_date, end_date = date_range.begin.to_date, date_range.end.to_date
          day_count = trading_day_count(date_range.begin, date_range.end)
          before_date, before_close, before_adj_close, before_volume = nearest_join(ticker_id, start_date, table, -1)
          after_date, after_close, after_adj_close, after_volume = nearest_join(ticker_id, end_date, table, 1)
          before_gap = before_date ? trading_day_count(before_date, start_date, false) : -1
          after_gap = after_date ? trading_day_count(end_date, after_date, false) : -1
          ycount = model.count(:conditions => { :ticker_id => ticker_id, :bardate => start_date..end_date })
          vol = [before_volume, after_volume].max
          flag = (before_gap == 1 && after_gap == 1 && (before_close - before_adj_close).abs/before_close < 0.01 && (after_close - after_adj_close).abs/after_close < 0.01) ? '***' : ''
          row = [ts.symbol, date_range.begin.to_date, date_range.end.to_date, day_count, before_close, before_adj_close, after_close, after_adj_close, before_date, after_date, before_gap, after_gap, vol, ycount, flag].map{ |el| el.nil? ? false : el }
          csv << row
          logger.info "(#{chunk.id}) #{symbol}\t#{cnt} of #{chunk.length}"
        end
      end
    end
  end
end
