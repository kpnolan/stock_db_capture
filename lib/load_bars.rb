# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'rubygems'
require 'ruby-debug'

module LoadBars

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
    DailyBar.update(logger)
  end

  def update_yahoo_history(logger)
    YahooBar.update(logger)
  end

  def update_google_history(logger)
    GoogleBar.update(logger)
  end

  def update_intraday_history(logger)
    IntraDayBar.update(logger)
  end

  def load_splits(logger)
    Split.load(logger)
  end

  def set_inactive_with_no_history
    ids = tickers_with_no_history('daily_bars')
    ids.each do |id|
      ticker = Ticker.find id
      ticker.update_attribute(:active, false)
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
end
