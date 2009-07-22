analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :stop15_2009, :time_period => 14 do |params, pass|
    rsi_ary = rsi(params.merge(:noplot => true, :result => :raw)).first
    indexes = under_threshold(20+pass*5, rsi_ary)
#    indexes.map do |start_index|
#      slope = linreg(start_index, :time_period => 10, :noplot => true)
#      slope > 0.02 ? start_index : nil
#    end
#    { :index => index, :eslope => slope }
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :stop15_2009, :time_period => 14 do |params, pass|
    params.reverse_merge! :noplot => true, :result => :raw
    rsi_ary = rsi(params).first
    rvi_ary = rvi(params).first
    rsi_idx = under_threshold(50-pass*5, rsi_ary).first
    rvi_idx = under_threshold(40-pass*5, rvi_ary).first

    case
    when rsi_idx.nil? && rvi_idx : rvi_idx
    when rsi_idx && rvi_idx : rsi_idx < rvi_idx ? rsi_idx : rvi_idx
    when rvi_idx.nil? && rsi_idx.nil? : nil
    when rvi_idx : rvi_idx
    when rsi_idx : rsi_idx
    end
  end

  desc "Close the position if the stop loss is 15% or greater"
  stop_loss(100.0)

end

populations do
  name = "daily_2009"
  start_date = Date.parse('1/2/2009')
  end_date = Date.parse('6/5/2009')
  liquid = "min(volume) >= 100000 and count(*) = #{total_bars(start_date, end_date, 1)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(start_date, end_date, 1)} bars"
  scan name, :start_date => start_date, :end_date => end_date, :conditions => liquid
end

backtests(:price => :close) do
  apply(:stop15_2009, :daily_2009) do
#    make_sheet()
  end
end
