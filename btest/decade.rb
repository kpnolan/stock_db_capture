# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

analytics do

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI gooes heads upwards of 30"
  entry_trigger :rsi_open_14, :time_period => 14, :result => :first do |params, pass|
    rsi_ary = rsi(params)
    indexes = under_threshold(20+pass*5, rsi_ary)
  end

  #-----------------------------------------------------------------------------------------------------------------
  # First use ad MACD to detect those RSI event which are on a downard slope, marking those that are not as valid.
  # For those with a negative MACD, use an anchored momentum. i.e. Set the close at trigger as the reference close
  # and return the index of the first trading day with a close higher than the reference date. Should weed out losers
  # on a downward trend
  desc 'Open triggered positions with a positive MACD or positive momentum'
  open_position :macd_relative_momentum, :time_period => 10 do |params|
    slope, corr = lrclose(params)
    slope = 0.0
    if slope < 0.0
      deltas = anchored_mom(:result => :gv)
      flags = deltas.where { |delta| delta > 0.0 }
      flags && flags[0]
    else
      0
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  exit_trigger :compact_rrm_14, :time_period => 14, :result => :first do |params|
    populate()
    if close[index_range.begin+3] < close[index_range.begin]
      timevec[index_range.begin+3]
    else
      close_crossing_value(#:macdfix => params.merge(:threshold => 0, :direction => :over, :result => :macd_hist),
                           :rsi => params.merge(:threshold => 50, :direction => :under, :result => :rsi),
                           :rvi => params.merge(:threshold => 50, :direction => :under, :result => :rvi))
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Close positions that have been triggered from an RVI or and RSI and whose indicatars have continued to climb until they peak out or level out"
  close_position :lagged_rsi_difference, :time_period => 14, :result => :first do |position, params|
    rsi_ary = rsi(params).to_a
    exit_rsi = rsi_ary.shift
    index = monotonic_sequence(exit_rsi, rsi_ary)
    index = (index == :max ? index_range.end : [index_range.begin, index-1].max)
    exit_date, exit_price = closing_values_at(index)
    if exit_date < position.xttime
      debugger
    end
    index
  end

  desc "Close the position if the stop loss is 15% or greater"
  #stop_loss(100.0)

end

populations do
  liquid = "min(volume) >= 75000"
   $scan_names = returning [] do |scan_vec|
     (2000..2000).each do |year|
       start_date = Date.civil(year, 1, 1)
       scan_name = "year_#{year}".to_sym
       end_date = start_date + 1.year - 1.day
       desc "Population of all stocks with a minimum valume of 75000 in #{start_date.year}"
       scan scan_name, :start_date =>  start_date, :end_date => end_date,
                       :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:macdfix, 9),
                       :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                       :order_by => 'tickers.symbol'
       scan_vec << scan_name
     end
   end
  # For 2009, since it's incomplete we have to do compute the scan differently by...
  # ...find the lastest daily bar in the DB (using IBM as the guiney pig)
  #latest_bar_date = DailyBar.maximum(:bartime, :include => :ticker, :conditions => "tickers.symbol = 'IBM'" ).to_date
  # end date keeps advancing as long as their 30 trading days which is the max hold time
  #end_date = Population.trading_date_from(latest_bar_date, -20)
  #desc "Population of all stocks with a minimum valume of 100000 from 2009-1-1 to #{end_date}"
  #scan 'year_2009', :start_date => '1/1/2009', :end_date => end_date,
  #                  :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
  #                  :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:macdfix, 9), :postfetch => 20
  #$scan_names << 'year_2009'
end

backtests(:generate_stats => false, :profile => false, :truncate => [], :repopulate => false, :log_flags => [:basic],
           :prefetch => 0, :postfetch => 20, :days_to_close => 20, :populate => false) do
  $scan_names.each do |scan_name|
    using(:rsi_open_14, :macd_relative_momentum, :compact_rrm_14, :lagged_rsi_difference, scan_name) do |entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan|
#      make_sheet(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan, :values => [:opening, :close, :high, :low, :volume], :pre_days => 1, :post_days => 30, :keep => true)
      #make_sheet(nil, nil, nil, nil, scan, :values => [:close], :pre_days => 1, :post_days => 30, :keep => true)
    end
  end
end

