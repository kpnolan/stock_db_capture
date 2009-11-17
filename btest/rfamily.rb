# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

study(:rfamily, :increment => :redo) do
  desc "Study the relationships between the favorite 'r' indicators and nreturn and close"
  factor :rsi, :time_period => 14
  factor :rvi, :time_period => 14
  factor :mom, :timer_period => 14
  factor :extract, :slot => :close
end

populations do
  name = "pos_2008"
#    liquid = "min(volume) > 100000 and count(*) = #{trading_count_for_year(year)}"
  year = 2008
  desc "Population of all stocks with a minimum valume of 100000 and have #{trading_count_for_year(year)} days traded in #{year}"
  scan name, :start_date => "01/02/#{year}", :end_date => "12/31/#{year}", :join => 'join samples on samples.ticker_id = daily_bars.ticker_id',
             :order_by => 'samples.ticker_id'
end

experiment(:timeseries => [:resolution => 1.day ]) do
  run :rfamily, :bypass => false, :version => :memory, :with => :pos_2008 do
    make_csv()
  end
end
