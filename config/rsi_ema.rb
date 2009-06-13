analytics do
  desc "Find all places where RSI gooes heads upwards of 30 and momentum confirms"
  open_position :rsi_ema, :threshold => 30, :time_period => 14 do |ts, params|
    rsi_memo = ts.rsi params.merge(:noplot => true, :result => :memo)
    rsi_idxs = rsi_memo.under_threshold(params[:threshold], :real)
  end

  desc "Find all places where RSI gooes heads upwards of 70 and momentum confirms"
  close_position :rsi_ema, :time_period => 5 do |ts, params|
    ts.ema :time_period => 3, :noplot => true
    ts.zema :time_period => 5, :noplot => true
    ts.crosses_over(:zema, :ema)
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
  apply(:rsi_ema, :liquid_2008)
end
