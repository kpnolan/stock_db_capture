analytics do

  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :compact_rrm_2009, :time_period => 14, :result => :first do |params, pass|
    rsi_ary = rsi(params)
    indexes = under_threshold(20+pass*5, rsi_ary)
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :compact_rrm_2009, :time_period => 14, :result => :first do |params|
    close_crossing_value(:macdfix => params.merge(:threshold => 0, :direction => :over, :result => :third),
                         :rsi => params.merge(:threshold => 50, :direction => :under),
                         :rvi => params.merge(:threshold => 50, :direction => :under))
  end

  desc "Close the position if the stop loss is 15% or greater"
  #stop_loss(100.0)

end

populations do
  # Find the lastest daily bar in the DB (using IBM as the guiney pig)
  latest_bar_date = DailyBar.maximum(:date, :include => :ticker, :conditions => "tickers.symbol = 'IBM'" )
  macd_bars = Timeseries.prefetch_bars(:macdfix, 9)
  name = "macd_2009"
  ## start way early to allow macd to settle out.
  pseudo_start_date = trading_days_from('1/2/2009', -macd_bars).last
  start_date = '1/2/2009'.to_date
  end_date = trading_days_from(latest_bar_date, -30).last # end date keeps advancing as long as we keep 30 days of foreward buffered ahead of us
  liquid = "min(volume) >= 100000 and count(*) = #{total_bars(pseudo_start_date, end_date)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(pseudo_start_date, end_date)} bars"
  scan name, :start_date => pseudo_start_date, :end_date => end_date, :conditions => liquid
end

backtests(:price => :close, :start_date => '1/2/2009'.to_date) do
  apply(:compact_rrm_2009, :macd_2009) do
#    make_sheet()
  end
end
