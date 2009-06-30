analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_rvi, :threshold => 30, :time_period => 14 do |ts, params|
    rsi5_30 = ts.rsi params.merge(:noplot => true, :result => :memo)
    indexes = rsi5_30.under_threshold(params[:threshold], :rsi)
    indexes.map do |start_index|
      slope = ts.linreg(start_index, :time_period => 10, :noplot => true)
      slope > 0.02 ? start_index : nil
    end
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :rsi_rvi, :threshold => 70, :time_period => 14 do |ts, params|
    rsi5_70 = ts.rsi params.merge(:noplot => true, :result => :memo)
    rvi = ts.rvi :time_period => 14, :noplot => true, :result => :memo
    r70 = rsi5_70.under_threshold(70, :rsi).first
    r60 = rvi.under_threshold(60, :rvi).first
    case
      when r70.nil? && r60 : r60
      when r70 && r60 : max(r70, r60)
      when r60.nil? : nil
      when r60 : r60
    end
  end
end

populations do
  name = "liquid_2009"
  start_date = Date.parse('1/2/2008')
  end_date = Date.parse('12/31/2008')
  liquid = "min(volume) > 100000 and count(*) = #{trading_day_count(start_date, end_date)}"

  desc "Population of all stocks with a minimum valume of 100000 and have#{trading_day_count(start_date, end_date)} days traded in 2009"
  scan name, :start_date => start_date, :end_date => end_date
end

backtests(:price => :close, :close_buffer => 30) do
  apply(:rsi_rvi, :liquid_2009) do
#    make_test()
  end
end
