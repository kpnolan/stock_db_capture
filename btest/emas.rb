indicators(:ema) do
  indicator :ema, :time_period => 5
  indicator :ema, :time_period => 14
  indicator :ema, :time_period => 22
  indicator :ema, :time_period => 30
end

indicators(:rsi) do
  indicator :rsi, :time_period => 5
  indicator :rsi, :time_period => 14
  indicator :rsi, :time_period => 22
  indicator :rsi, :time_period => 30
end

indicators(:rvi) do
  indicator :rvi, :time_period => 5
  indicator :rvi, :time_period => 14
  indicator :rvi, :time_period => 22
  indicator :rvi, :time_period => 30
end


populations do
  name = "ta_positions_2009"
  desc "populations of a stocks which held positions in 2009"
  scan name, :start_date => "01/02/2009",
             :end_date => "6/5/2009",
             :join => 'left outer join positions on positions.ticker_id = daily_bars.ticker_id '+
                      'left outer join tickers on tickers.id = positions.ticker_id',
             :order_by => 'positions.ticker_id'
end

run(:resolution => 1.day) do
  apply(:ema, :ta_positions_2009)
  apply(:rsi, :ta_positions_2009)
  apply(:rvi, :ta_positions_2009)
end
