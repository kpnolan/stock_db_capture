analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_rvi_macd_2009, :time_period => 14 do |params, pass|
    rsi_ary = rsi(params.merge(:noplot => true, :result => :raw)).first
    indexes = under_threshold(20+pass*5, rsi_ary)  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :rsi_rvi_macd_2009, :time_period => 14 do |params, pass|
    params.reverse_merge! :noplot => true, :result => :raw
    rsi_ary = rsi(params).first
    rvi_ary = rvi(params).first
    macd_ary = macd().third # the args are all defaulted to the std values (the ones you were using), the 3rd return val
    rsi_idx = under_threshold(50-pass*5, rsi_ary).first
    rvi_idx = under_threshold(40-pass*5, rvi_ary).first
    macd_idx = over_threshold(0, macd_ary).first

    [rsi_idx, rvi_idx, macd_idx].min do |a,b|
      case
      when a && b : a <=> b
      when a.nil? && b : 1
      when b.nil? && a : -1
      else 0
      end
    end
  end

  desc "Close the position if the stop loss is 15% or greater"
  #stop_loss(100.0)

end

populations do
  name = "daily_2009"
  ## start way early to allow macd to settle out.
  start_date = Date.parse('10/1/2008')
  end_date = Date.parse('6/5/2009')
  liquid = "min(volume) >= 100000 and count(*) = #{total_bars(start_date, end_date, 1)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(start_date, end_date, 1)} bars"
  scan name, :start_date => start_date, :end_date => end_date, :conditions => liquid
end

backtests(:price => :close) do
  apply(:rsi_rvi_macd_2009, :daily_2009) do
#    make_sheet()
  end
end
