analytics do

  desc "Find all places where RSI gooes heads upwards of 30"
  open_position :rsi_open_14, :time_period => 14, :result => :first do |params, pass|
    rsi_ary = rsi(params)
    indexes = under_threshold(20+pass*5, rsi_ary)
  end

  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  close_position :compact_rrm_14, :time_period => 14, :result => :first do |params|
    close_crossing_value(:macdfix => params.merge(:threshold => 0, :direction => :over, :result => :third),
                         :rsi => params.merge(:threshold => 50, :direction => :under),
                         :rvi => params.merge(:threshold => 50, :direction => :under))
  end
end

populations do
  liquid = "min(volume) >= 100000"
  start_date = '1/1/2000'.to_date
  $scan_names = returning [] do |scan_vec|
    9.times do
      scan_name = "year_#{date.year}".to_sym
      end_date = start_date + 1.year - 1.day
      desc "Population of all stocks with a minimum valume of 100000 in #{date.year}"
      scan scan_name, :start_date =>  start_date, :end_date => end_date, :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:macdfix, 9)
      start_date += 1.year
      scan_vec << scan_name
    end
  end
end

backtests do
  $scan_names.each do |scan_name|
    using(:rsi_open_14, :compact_rrm_14, scan_name) do |entry_strategy, exit_strategy, scan|
      make_sheet(entry_strategy, exit_strategy, scan)
    end
  end
end
