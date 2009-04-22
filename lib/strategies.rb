require 'strategy_engine'

analytics do

  desc "Find all places where RSI gooes under 30"
  open_position :rsi_oversold, :threshold => 30, :time_period => 15 do |ts, params|
    memo = ts.rsi params.merge(:noplot => true, :result => :memo)
    memo.under_threshold(params[:threshold], :real)
  end

  desc "Find all places where the low of a day crosses below 2 std dev form the SMA(5)"
  open_position :bband_overshold, :time_period => 5, :deviations_up => 2.0, :deviations_down => 2.0 do |ts, params|
    memo = ts.bband params.merge(:noplot => true, :result => :memo)
    memo.crosses_over(:price, :lower_band)
  end

  desc "Find all date where Relative Volatility Index (RVI) is greater then 50"
  open_position :rvi, :time_period => 5, :threshold => 50  do |ts, params|
    memo = ts.rvi params.merge(:noplot => true, :result => :memo)
    memo.over_threshold(params[:threshold], :rvi)
  end
end

populations do
  liquid = 'min(volume) > 100000 and count(*) > 100'
  0.upto(8) do |year|
    desc "Population of all stocks with a minimum value of 100000 and at least100 days traded in #{2000+yaer}"
    scan "liquid_#{2000+year}", :start_date => "01/01/#{2000+year}", :end_date => "12/31/#{2000+year}", :conditions => liquid

    desc "Flat stocks of #{2000+year}"
    scan "flat_#{2000+year}", :start_date => "01/01/#{2000+year}", :end_date => "12/31/#{2000+year}", :conditions => liquid+' and stddev(close)/avg(close) < 0.25 and count(*) > 100'

    desc "Volatile stocks of #{2000+year}"
    scan "volatile_#{2000+year}", :start_date => "01/01/#{2000+year}", :end_date => "12/31/#{2000+year}", :conditions => liquid+' and stddev(close)/avg(close) > 1 and count(*) > 100'

    desc "Big Daily Swings of #{2000+year}"
    scan "active_swings_#{2000+year}", :start_date => "01/01/#{2000+year}", :end_date => "12/31/#{2000+year}", :conditions => liquid+' and avg(high-low)/avg((high+low)/2) > 0.1'
  end
end

backtests do

  apply(:ris_oversold, :liquid_08) do |positions|
    positions.each { |position| position.close_at_max(:hold_time => 1..10) }
  end
end

$backtester.run
