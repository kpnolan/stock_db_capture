analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_rvi_stop, :time_period => 14 do |ts, params|
    params.reverse_merge!(:noplot => true, :result => :memo)
    rsi = ts.rsi params
    indexes = rsi.under_threshold(30, :rsi)
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :rsi_rvi_stop, :time_period => 14 do |ts, params|
    params.reverse_merge! :noplot => true, :result => :memo
    rsi = ts.rsi params
    rvi = ts.rvi params
    r70 = rsi.under_threshold(60, :rsi).first
    r60 = rvi.under_threshold(50, :rvi).first
    case
      when r70.nil? && r60 : r60
      when r70 && r60 : min(r70, r60)
      when r60.nil? : nil
      when r60 : r60
    end
  end

  desc "Close the position if the stop loss is 1% or greater"
  stop_loss(1.0)
end

populations do
  name = "intraday_2009"
  start_date = Date.parse('1/2/2009')
  end_date = Date.parse('4/30/2009')
  liquid = "min(accum_volume) > 100000 and count(*) = #{total_bars(start_date, end_date, 13)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(start_date, end_date, 13)} bars"
  scan name, :table_name => 'intra_day_bars', :start_date => start_date, :end_date => end_date, :conditions => liquid
end

backtests(:price => :close, :close_buffer => 20) do
  apply(:rsi_rvi_stop, :intraday_2009) do
#    make_test()
  end
end
