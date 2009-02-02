module Aggregator

  BEGIN_TIME = 9.hours + 30.minutes
  END_TIME = 16.hours
  UTC_OFFSET = 8.hours

  def compute_aggregate(symbol, date, period_in_seconds)
    tid = Ticker.find_by_symbol(symbol).id
    unless (close_start_ary = find_beginnings(tid, date, period_in_seconds)).empty?
      last_close = close_start.first.first
      start_time = Time.parse(close_start_ary.first.last) + period_in_seconds.seconds
    else
      start_time = date.to_time + BEGIN_TIME
    #  last_close = DailyClose.connection.select_value("select close from daily_closes where ticker_id = #{tid} having max(date) < '#{date.to_s(:db)}'") # FIXME make robust!
    end
    end_time = start_time + period_in_seconds
    exit_time = date.to_time + END_TIME
    num_aggregates = 0;
    while (end_time <= exit_time) do
      recs = find(:all, :conditions => form_where_clause(tid, start_time, end_time), :order => 'last_trade_time')
      begin
        unless recs.empty?
          last_close = recs.first.last_trade if last_close.nil?
          last_close = generate_aggregate(tid, date, start_time, period_in_seconds, last_close, recs)
        end
      rescue => e
        $logger.error("#{symbol}: #{e.message}")
        num_aggregates -= 1
      end
      num_aggregates += 1  unless recs.empty?
      start_time += period_in_seconds
      end_time = start_time + period_in_seconds
    end
    $logger.info("#{symbol}:\t #{num_aggregates} generated for #{date}")
  end

  def form_where_clause(tid, btime, etime)
    where = "ticker_id = #{tid} AND last_trade_time >= '#{btime.to_s(:db)}' AND last_trade_time < '#{etime.to_s(:db)}'"
  end

  def generate_aggregate(tid, date, start_time, period, last_close, recs)
    tid = recs.first.ticker_id
    open = recs.first.last_trade
    close = recs.last.last_trade
    high = recs.inject(0.0) { |max, rec| rec.last_trade > max ? rec.last_trade : max }
    low = recs.inject(high) { |min, rec| rec.last_trade < min ? rec.last_trade : min }
    vol = recs.inject(0) { |sum, rec| sum + rec.volume }
    avg_volume = vol / recs.length
    r = close/last_close
    logr = Math.log(r)

    Aggregate.create!(:ticker_id => tid, :date => date, :start => start_time-UTC_OFFSET, :open => open,
                      :close => close, :high => high, :low => low, :volume => vol, :period => period,
                      :r => r, :logr => logr, :sample_count => recs.length, :avg_volume => avg_volume)
    return close
  end

  def find_beginnings(tid, date, period_in_seconds)
    Aggregate.connection.select_rows("select close, start from aggregates where ticker_id = #{tid} and period = #{period_in_seconds} and date = '#{date.to_s(:db)}' order by start desc limit 1")
  end

  def out_of_date
    dates = connection.select_values('select distinct date(last_trade_time) from live_quotes left outer join aggregates on date(last_trade_time) = date where aggregates.id is null')
    dates.map { |d| Date.parse(d) }.sort
  end
end

