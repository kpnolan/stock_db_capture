# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

analytics do

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where the rvigor signal crosses over the rivgor"
  entry_trigger :rvig_open, :time_period => 10, :indicator => :rvigor do |params, pass|
    rvig, rvigSig = rvig(:result => [:rvigor, :rvigor_sig])
    up_indexes = crosses_over(rvigSig, rvig)
    up_crossings = up_indexes.select { |i| result_at(i, :rvigor) <= -15.0 }
    up_tuples = slope_at_crossing(rvig, rvigSig, up_crossings).select {  |tuple| tuple.last < 100.0 }
    up_tuples.map(&:first)
  end

  #-----------------------------------------------------------------------------------------------------------------
  # First use ad MACD to detect those RSI event which are on a downard slope, marking those that are not as valid.
  # For those with a negative MACD, use an anchored momentum. i.e. Set the close at trigger as the reference close
  # and return the index of the first trading day with a close higher than the reference date. Should weed out losers
  # on a downward trend
  desc 'Placeholder to detect slopes of rvig and its signal'
  open_position :identity do |params|
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI gooes heads upwards of 70 OR go back under 30 after crossing 30"
  exit_trigger :rvig_close, :time_period => 10, :indicator => :rvigor do |params|
    rvig, rvigSig = rvig(:result => [:rvigor, :rvigor_sig])
    dn_indexes = crosses_under(rvigSig, rvig)
    dn_crossings = dn_indexes.select { |i| result_at(i, :rvigor) >= 10.0 }
    dn_tuples = slope_at_crossing(rvig, rvigSig, dn_crossings).select {  |tuple| tuple.last < 100.0 }
    if dn_tuples.empty?
      nil
    else
      [index2time(dn_tuples[0].first), :rvigor, dn_tuples[0].second]
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "This does nothing"
  close_position :identity do |position, params|
  end

  desc "Close the position if the stop loss is 15% or greater"
  #stop_loss(100.0)

end

populations do
  liquid = "min(volume) >= 75000"
   $scan_names = returning [] do |scan_vec|
    (2000..2008).each do |year|
      start_date = Date.civil(year, 1, 1)
      scan_name = "year_#{year}".to_sym
      end_date = start_date + 1.year - 1.day
      desc "Population of all stocks with a minimum valume of 75000 in #{start_date.year}"
      scan scan_name, :start_date =>  start_date, :end_date => end_date,
                       :conditions => liquid,
                       :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                       :order_by => 'tickers.symbol', :prefetch => 28, :postfetch => 45
       scan_vec << scan_name
     end
   end

  # For 2009, since it's incomplete we have to do compute the scan differently by...
  # ...find the lastest daily bar in the DB (using IBM as the guiney pig)
  # end date keeps advancing as long as their 30 trading days which is the max hold time
  desc "Population of all stocks with a minimum valume of 100000 for 2009"
  start_date = '1/1/2009'.to_date
  scan 'year_2009', :start_date => start_date, :end_date => start_date + 1.year - 1.day,
                    :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                    :conditions => liquid, :prefetch => 28, :postfetch => 45, :count => 295
  $scan_names << 'year_2009'
end

backtests(:generate_stats => false, :profile => false, :truncate => [], :repopulate => false, :log_flags => [:basic],
          :days_to_close => 45, :populate => false, :epass => 0..0) do
  $scan_names.each do |scan_name|
    using(:rvig_open, :identity, :rvig_close, :identity, scan_name) do |entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan|
#      make_sheet(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan, :values => [:opening, :close, :high, :low, :volume], :pre_days => 1, :post_days => 30, :keep => true)
      #make_sheet(nil, nil, nil, nil, scan, :values => [:close], :pre_days => 1, :post_days => 30, :keep => true)
    end
  end
end

