module Aggregator

  BEGIN_TIME = 9.hours + 30.minutes
  END_TIME = 16.hours
  UTC_OFFSET = 5.hours # to Eastern Time

  def compute_aggregates(period_in_seconds)
    tickers = Ticker.find(:all, :conditions => { :active => true, :dormant => false } , :order => 'id')
    count = 1
    $logger.info("beginning out_of_date query with #{tickers.length} tickers...")
    date = Date.today
    for ticker in tickers
      $logger.info("Aggregating #{ticker.symbol} #{count} out of #{tickers.length}")
      compute_aggregate(ticker.symbol, date, period_in_seconds)
      count += 1
    end
  end

  def compute_aggregate(symbol, date, period_in_seconds)
    tid = Ticker.find_by_symbol(symbol).id
    start_time = date.to_time + BEGIN_TIME

    date1, last_close1 = DailyClose.find_last_close(tid, date)
    date2, last_close2 = Aggregate.find_last_close(tid, date)

    last_close = case
      when date1 < date2 : last_close2.to_f
      when date1 > date2 : last_close1.to_f
    else                   last_close1.to_f
    end

    end_time = start_time + period_in_seconds
    exit_time = date.to_time + END_TIME
    while (end_time <= exit_time) do
      recs = LiveQuote.find(:all, :conditions => form_where_clause(tid, start_time, end_time), :order => 'last_trade_time')
      unless recs.empty?
        last_close = generate_aggregate(tid, date, start_time, period_in_seconds, last_close, recs)
        num_aggregates += 1
      end
      start_time += period_in_seconds
      end_time = start_time + period_in_seconds
    end
  end

  def form_where_clause(tid, btime, etime)
    where = "ticker_id = #{tid} AND last_trade_time >= '#{btime.to_s(:db)}' AND last_trade_time < '#{etime.to_s(:db)}'"
  end

  def generate_aggregate(tid, date, start_time, period, last_close, recs)
    open = recs.first.last_trade.to_f
    close = recs.last.last_trade.to_f
    last_trades = recs.collect { |r| r.last_trade }
    volume = recs.last.volume - recs.first.volume
    high = last_trades.max
    low = last_trades.min
    r = close/last_close
    logr = Math.log(r)

    Aggregate.create!(:ticker_id => tid, :date => date, :start => start_time+UTC_OFFSET, :open => open,
                      :close => close, :high => high, :low => low, :volume => volume, :period => period,
                      :r => r, :logr => logr, :sample_count => recs.length)
    return close
  end

  def out_of_date
    dates = LiveQuote.connection.select_values('select distinct(date(last_trade_time)) from live_quotes')
  end
end

