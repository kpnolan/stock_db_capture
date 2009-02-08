module Aggregator

  A = %w{ 454 663
774
914
1165
2902
3015
3264
3365
3410
3461
3655
3907
4839
4973
5067
5094
5140
5205
5237
5262
5291
5328
5365
5389
5392
5412
5471
5533
5539
5573
5617
5620
5628
5660
5681
5695
5758
5788
5794 }


  BEGIN_TIME = 9.hours + 30.minutes
  END_TIME = 16.hours
  UTC_OFFSET = 5.hours # to Eastern Time

  def compute_aggregates(period_in_seconds)
    tickers = Tickers.find A
#    tickers = Ticker.find(:all, :conditions => "active = 1 and dormant = 0 and id >= 5793" , :order => 'id')
#    tickers = Ticker.find(:all, :conditions => { :active => true, :dormant => false} , :order => 'id')
    count = 1
    $logger.info("beginning out_of_date query with #{tickers.length} tickers...")
    dates = out_of_date()
    for ticker in tickers
      $logger.info("Aggregating #{ticker.symbol} #{count} out of #{tickers.length}")
      for date in dates
        #$logger.info("Computing Date: #{date}")
        compute_aggregate(ticker.symbol, date, period_in_seconds)
      end
      count += 1
      if count == 1
        break;
      end
    end
  end

  def compute_aggregate(symbol, date, period_in_seconds)
    tid = Ticker.find_by_symbol(symbol).id
    unless (close_start_ary = find_beginnings(tid, date, period_in_seconds)).empty?
      last_close = close_start.first.first.to_f
      start_time = Time.parse(close_start_ary.first.last) + period_in_seconds.seconds
    else
      start_time = date.to_time + BEGIN_TIME
      last_close = DailyClose.connection.select_value("select close from daily_closes where ticker_id = #{tid} having max(date) < '#{date}'").to_f # FIXME make robust!
    end
    end_time = start_time + period_in_seconds
    exit_time = date.to_time + END_TIME
    num_aggregates = 0;
    while (end_time <= exit_time) do
      recs = LiveQuote.find(:all, :conditions => form_where_clause(tid, start_time, end_time), :order => 'last_trade_time')
      #begin
        unless recs.empty?
          last_close = recs.first.last_trade if last_close.nil?
          last_close = generate_aggregate(tid, date, start_time, period_in_seconds, last_close, recs)
        end
      #rescue => e
      #  $logger.error("#{symbol}: #{e.message}")

      #num_aggregates -= 1
      #end
      num_aggregates += 1  unless recs.empty?
      start_time += period_in_seconds
      end_time = start_time + period_in_seconds
    end
    #$logger.info("#{symbol}:\t #{num_aggregates} generated for #{date}")
  end

  def form_where_clause(tid, btime, etime)
    where = "ticker_id = #{tid} AND last_trade_time >= '#{btime.to_s(:db)}' AND last_trade_time < '#{etime.to_s(:db)}'"
  end

  def generate_aggregate(tid, date, start_time, period, last_close, recs)
    open = recs.first.last_trade
    close = recs.last.last_trade
    last_trades = recs.collect { |r| r.last_trade }
    volume = recs.last.volume - recs.first.volume
    high = last_trades.max
    low = last_trades.min
    unless close.class == String || last_close.class == String
      r = close/last_close
      logr = Math.log(r)
    else
      puts "tid: #{tid} start_time: #{start_time} close: #{close} last_close: #{last_close}"
      r = 1.0
      logr = 0.0;
    end

    Aggregate.create!(:ticker_id => tid, :date => date, :start => start_time+UTC_OFFSET, :open => open,
                      :close => close, :high => high, :low => low, :volume => volume, :period => period,
                      :r => r, :logr => logr, :sample_count => recs.length)
    return close
  end

  def find_beginnings(tid, date, period_in_seconds)
    b = Aggregate.connection.select_rows("select close, start from aggregates where ticker_id = #{tid} and period = #{period_in_seconds} and date = '#{date}' order by start desc limit 1")
    puts b.join(', ')
  end

  def out_of_date
    dates = LiveQuote.connection.select_values('select distinct(date) from live_quotes')
  end
end

