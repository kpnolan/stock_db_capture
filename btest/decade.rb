analytics do

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI gooes heads upwards of 30"
  entry_trigger :rsi_open_14, :time_period => 14, :result => :first do |params, pass|
    rsi_ary = rsi(params)
    indexes = under_threshold(20+pass*5, rsi_ary)
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Use an anchored momentum. I.e. Set the close at trigger as the reference close and return the index of the " +
    "first trading day with a close higher than the reference date. Should weed out losers on a downward trend"
  open_position :macd_relative_momentum, :result => :first do |params|
    macd_hist = macdfix(:result => :macd_hist).to_a
    #log_result(:macd_hist)
    if (index = macd_hist.index { |val| val >= 0.0 })
      #log_result("matched at: #{index}")
      [index+result_offset]
    else
      delta_closes = anchored_mom(params)
      indexes = under_threshold(0.0, delta_closes)
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  exit_trigger :compact_rrm_14, :time_period => 14, :result => :first do |params|
    close_crossing_value(:macdfix => params.merge(:threshold => 0, :direction => :over, :result => :macd_hist),
                         :rsi => params.merge(:threshold => 50, :direction => :under, :result => :rsi),
                         :rvi => params.merge(:threshold => 50, :direction => :under, :result => :rvi))
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
  liquid = "min(volume) >= 100000"
  $scan_names = returning [] do |scan_vec|
    (2001..2008).each do |year|
      start_date = Date.civil(year, 1, 1)
      scan_name = "year_#{year}".to_sym
      end_date = start_date + 1.year - 1.day
      desc "Population of all stocks with a minimum valume of 100000 in #{start_date.year}"
      scan scan_name, :start_date =>  start_date, :end_date => end_date,
                      :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:macdfix, 9)
      scan_vec << scan_name
    end
  end
end

backtests(:generate_stats => false, :profile => false, :truncate => :scan) do
  $scan_names.each do |scan_name|
  using(:rsi_open_14, :macd_relative_momentum, :compact_rrm_14, :lagged_rsi_difference, scan_name) do |entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan|
#      make_sheet(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan, :values => [:opening, :close, :high, :low, :volume], :pre_days => 1, :post_days => 30, :keep => true)
      make_sheet(nil, nil, nil, nil, scan, :values => [:close], :pre_days => 1, :post_days => 40, :keep => true)
    end
  end
end

