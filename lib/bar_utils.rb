#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

# If was forced into this conditional load because the file was always being loaded twice
require 'trading_calendar' if $".grep(/trading_calendar/).empty?

module BarUtils

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
    sql = "select symbol, max(bardate) from #{table} left outer join tickers on tickers.id = ticker_id  group by ticker_id having max(bardate) < '#{latest_date.to_s(:db)}' order by symbol"
    DailyBar.connection.select_rows(sql)
  end

  def tickers_with_lagging_intraday(latest_date)
    sql = "select symbol, max(bardate) from intra_day_bars left outer join tickers on tickers.id = ticker_id where active = 1 group by ticker_id having max(bardate) < '#{latest_date.to_s(:db)}' order by symbol"
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
      when 'yahoo_bars'  then b_close = 'b.adj_close'
      when 'google_bars' then b_close = 'b.close'
    end
    case direction
      when -1 then relop, sort = '<', 'desc'
      when  1 then relop, sort = '>', 'asc'
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

  def load_bars(logger, qs, table)
    ticker_ids = tickers_with_no_history(table)
    chunk = Splitter.new(ticker_ids)
    count = 0
    min_date = Date.parse('1999-1-1')
    max_date = Date.today
    for ticker_id in chunk do
      ticker = Ticker.find ticker_id
      symbol = ticker.symbol
      next if symbol.include? '-'
      bars = qs.dailys_for(symbol, min_date, max_date)
      logger.info "(#{chunk.id}) loading #{symbol}\t#{min_date}\t#{max_date}\t#{bars.length}\tbars\t#{count} of #{chunk.length}"
      bars.each { |bar| create_bar(symbol, ticker_id, bar) }
      count += 1
    end
  end

  def update_bars(logger, qs, table)
    tuples = tickers_with_lagging_history(table)
    end_date = latest_date()
    chunk = Splitter.new(tuples)
    count = 0
     for tuple in chunk do
      symbol, max_date = tuple
      next if symbol.include? '-'
      max_date = Date.parse(max_date)
      start_date = max_date + 1.day
      td = BarUtils.trading_day_count(start_date, end_date)
      next if td.zero?
      ticker = Ticker.lookup(symbol)
      bars = qs.dailys_for(symbol, start_date, end_date)
      logger.info "(#{chunk.id}) loading #{symbol}\t#{start_date}\t#{end_date}\t#{bars.length}\tbars\t#{count} of #{chunk.length}"
      bars.each { |bar| create_bar(symbol, ticker.id, bar) }
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

  def init_logger(filename)
    path = File.join(RAILS_ROOT, 'log', filename.to_s+'.log')
    system("cat /dev/null > #{path}")
    logger = ActiveSupport::BufferedLogger.new(path)
  end

  class Splitter
    attr_reader :id, :sub_array
    def initialize(id_array)
      @id = ENV['PROC_ID'].nil? ? 0 :  ENV['PROC_ID'].to_i
      count = ENV['PROC_CNT'].nil? ? 1 :  ENV['PROC_CNT'].to_i
      len = id_array.length
      chunk_size = len / count
      chunk_start = id * chunk_size
      chunk_end = ((id == count - 1) ? len - 1 : chunk_start + chunk_size - 1)
      @sub_array = id_array[chunk_start..chunk_end]
    end

    def length()
      sub_array.length
    end

    def items()
      sub_array
    end

    def each()
      sub_array.each { |id| yield id }
    end
  end

  class ForkSplitter
    attr_reader :chunks, :child_count
    def initialize(id_array)
      @chunks = []
      @child_count = extract_children()
      len = id_array.length
      chunk_size = len / child_count
      for index in 0..child_count
        chunk_start = index * chunk_size
        chunk_end = ((index == child_count - 1) ? len - 1 : chunk_start + chunk_size - 1)
        @chunks[index] = id_array[chunk_start..chunk_end]
      end
    end

    def part_info
      return child_count, chunks
    end

    private

    def extract_children
      matches = ENV.keys.grep(/^CHILD/)
      raise ArgumentError, "multiple matches: [#{matches.join(', ')}] for ENV var starting with 'CHILD'" if matches.length > 1
      return 1 if matches.empty?
      ENV[matches.first].to_i
    end
  end

  def log_status(logger, status_ary)
    status_objs = status_ary.map(&:second)
    status_objs.each { |stat| logger.info(stat.to_s) }
  end
end
