# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

study(:amm, :increment => :redo) do
  desc "Create a timeseries to test Adylula ANN"
  factor :extract, :slot => :bardate
  factor :extract, :slot => :opening
  factor :extract, :slot => :high
  factor :extract, :slot => :low
  factor :extract, :slot => :close
  factor :extract, :slot => :volume
  factor :ad
  factor :rsi, :time_period => 14
  factor :stock, :slow_k_period => 5, :slow_d_period => 8
  factor :willr, :time_period => 2
  factpr :arm_oem
  factor :obv
  factor :pvt

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
