analytics do
  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_rvi, :threshold => 30, :time_period => 14 do |ts, params|
    rsi5_30 = ts.rsi params.merge(:noplot => true, :result => :memo)
    indexes = rsi5_30.under_threshold(params[:threshold], :rsi)
    indexes.map do |start_index|
      slope = ts.linreg(start_index, :time_period => 10, :noplot => true)
      slope > 0.01 ? start_index : nil
    end
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :rsi_rvi, :threshold => 70, :time_period => 14 do |ts, params|
    rsi5_70 = ts.rsi params.merge(:noplot => true, :result => :memo)
    rvi = ts.rvi :time_period => 14, :noplot => true, :result => :memo
    r70 = rsi5_70.under_threshold(70, :rsi).first
    r40 = rvi.over_threshold(40, :rvi).first
    case
      when r70.nil? && r40 : r40
      when r70 && r40 : min(r70, r40)
      when r40.nil? : nil
      when r40 : r40
    end
  end
end

populations do
  $names = []
  for year in 2000..2008
    name = "liquid_#{year}"
    liquid = "min(volume) > 100000 and count(*) = #{trading_count_for_year(year)}"
    desc "Population of all stocks with a minimum valume of 100000 and have #{trading_count_for_year(year)} days traded in #{year}"
    scan name, :start_date => "01/01/#{year}", :end_date => "12/31/#{year}", :conditions => liquid
    $names << name
  end
end

backtests(:price => :close) do
  apply(:rsi_rvi, :liquid_2008) do
#    make_test()
  end
end
