analytics do

  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_open_14, :time_period => 14, :result => :first do |params, pass|
    rsi_ary = rsi(params)
    indexes = under_threshold(20+pass*5, rsi_ary)
    #unless indexes.empty?
    #  macd_hist = macdfix(:results => :third)
    #  indexes.select { |idx| macd_hist[idx-outidx] >= 0.0 }
    #else
    #  []
    #end
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :compact_rrm_14, :time_period => 14, :result => :first do |params|
    close_crossing_value(:macdfix => params.merge(:threshold => 0, :direction => :over, :result => :third),
                         :rsi => params.merge(:threshold => 50, :direction => :under),
                         :rvi => params.merge(:threshold => 50, :direction => :under))
  end

  desc "Close the position if the stop loss is 15% or greater"
  #stop_loss(100.0)

end

populations do
  # Find the lastest daily bar in the DB (using IBM as the guiney pig)
  latest_bar_date = DailyBar.maximum(:bartime, :include => :ticker, :conditions => "tickers.symbol = 'IBM'" ).to_date
  # end date keeps advancing as long as their 30 trading days which is the max hold time
  end_date = Population.trading_date_from(latest_bar_date, -30)

  liquid = "min(volume) >= 100000"
  desc "Population of all stocks with a minimum valume of 100000"
  scan 'macd_2009', :start_date => '1/2/2009', :end_date => end_date, :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:macdfix, 9)
end

# Validate options are:
#   :generate_stats => true|false   generate a table which gives the values of the technical indicators used in the backtest at each bar.
#                                   Used to generate meaninful reports, in R, of both bars and the values of the tecnical indicators at each bar
#   :tuncate => [:entry_strategy | :exit_strategy | scan ] trucates thos positions matching the ones used in this backtest. Avoids collisions
#   :epass => range                 controls the number of values at with the entry pass number is run. Defaults to 0..2
#   :profile => (true|false)        turns on or off profiling. Defaults to false
#   :resolution => 1.day            determintes at which resolution the backtest is run, currently on 1.day and 30.minutes is value
#   :price => :close                determines the price used for calculation
#   :days_to_close                  max number of days to hold open a position before closing it forcefully
#
backtests(:generate_stats => false, :truncate => :scan, :profile => false) do
  using(:rsi_open_14, :compact_rrm_14, :macd_2009) do |entry_strategy, exit_strategy, scan|
    #make_sheet(entry_strategy, exit_strategy, scan)
  end
end
