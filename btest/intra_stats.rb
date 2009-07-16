daily_params = { :resolution => 1.day }
intra_params = { :resolution => 30.minutes, :stride => 13, :stride_offset => 0, :pre_buffer => 0, :post_buffer => 0 }

study(:intra_stats, :increment => :redo) do
  desc "Study the relationships between the favorite 'r' indicators and nreturn and close"
  factor :rsi, daily_params.merge(:time_period => 14)
  factor :rvi, daily_params.merge(:time_period => 14)
  factor :extract, daily_params.merge(:slot => [:logr, :close])
  factor :extract, intra_params.merge(:slot => [ :delta, :volume] )
end

populations do
  name = "intraday"
  start_date = Date.parse('1/2/2009')
  end_date = Date.parse('5/29/2009')
  liquid = "min(accum_volume) > 100000 and count(*) = #{total_bars(start_date, end_date, 13)}"
  desc "Population of all stocks with a minimum valume of 100000 and have  #{total_bars(start_date, end_date, 13)} bars"
  scan name, :table_name => 'intra_day_bars', :start_date => start_date, :end_date => end_date, :conditions => liquid
end

experiment(:timeseries => [ daily_params, intra_params ] ) do
  run :rfamily, :bypass => false, :version => :memory, :limit => 10, :with => :intraday do
    make_csv()
  end
end
