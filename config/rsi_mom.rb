analytics do
  desc "Find all places where RSI gooes heads upwards of 30 and momentum confirms"
  open_position :rsi_oversold_mom, :threshold => 30, :time_period => 5 do |ts, params|
    rsi_memo = ts.rsi params.merge(:noplot => true, :result => :memo)
    rsi_idxs = rsi_memo.under_threshold(params[:threshold], :real)
    mom_memo = ts.mom :time_period => 12, :noplot => true, :result => :memo
    mom_idxs = mom_memo.under_threshold(0, :real)
    tuples = ts.intersect(rsi_idxs, mom_idxs, 1.week)
    tuples.map { |tuple| tuple.first }
  end

  desc "Find all places where RSI gooes heads upwards of 70 and momentum confirms"
  close_position :rsi_oversold_mom, :threshold => 70, :time_period => 5 do |ts, params|
    rsi_memo = ts.rsi params.merge(:noplot => true, :result => :memo)
    rsi_idxs = rsi_memo.under_threshold(params[:threshold], :real)
    mom_memo = ts.mom :time_period => 12, :noplot => true, :result => :memo
    mom_idxs = mom_memo.over_threshold(0, :real)
    tuples = ts.intersect(rsi_idxs, mom_idxs, 1.week)
    tuples.map { |tuple| tuple.first }
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
  apply(:rsi_oversold_mom, :liquid_2008)
end
