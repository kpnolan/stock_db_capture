analytics do
  desc "Find all places where RSI gooes under 30"
  open_position :aroonosc_up, :threshold => -50.0, :time_period => 14 do |ts, params|
      memo = ts.aroonosc params.merge(:noplot => true, :result => :memo)
      memo.under_threshold(-50.0, :real)
  end

  open_position :aroonosc_down, :short => true, :threshold => 0, :time_period => 14 do |ts, params|
      memo = ts.aroonosc params.merge(:noplot => true, :result => :memo)
      memo.over_threshold(50, :real)
  end
end

populations do
  liquid = 'min(volume) > 100000 and count(*) > 250'
  year = 8
  desc "Population of all stocks with a minimum value of 100000 and at least 250 days traded in #{2000+year}"
  scan "liquid_#{2000+year}", :start_date => "01/01/#{2000+year}", :end_date => "12/31/#{2000+year}", :conditions => liquid
end

backtests(:price => :close) do
  apply(:aroonosc_up, :liquid_2008) do |ts, params|
    memo = ts.aroonosc params.merge(:noplot => true, :result => :memo)
    memo.over_threshold(0, :real)
  end
#  apply(:aroonosc_down, :liquid_2008) do |ts, params|
#    memo = ts.aroonosc params.merge(:noplot => true, :result => :memo)
#    memo.under_threshold(0, :real)
#  end
end
