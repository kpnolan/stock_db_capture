#--
# Copyright (c) 2008-20010 Kevin Patrick Nolan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

analytics do

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where the rvigor signal crosses over the rivgor"
  entry_trigger :rvig_open, :time_period => 5, :result => [:rvigor, :rvigor_sig], :method => :crosses_under do |params, pass|
    rvig, rvigSig = rvig(:result => params[:result])
    indexes = send(params[:method], rvigSig, rvig)
    crossings = indexes.select { |i| result_at(i, :rvigor) <= -15.0 }
  #  under_tuples = slope_at_crossing(rvig, rvigSig, crossings).select {  |tuple| tuple.last == -1 }
#    under_tuples.map(&:first)
    crossings
  end

  #-----------------------------------------------------------------------------------------------------------------
  # First use ad MACD to detect those RSI event which are on a downard slope, marking those that are not as valid.
  # For those with a negative MACD, use an anchored momentum. i.e. Set the close at trigger as the reference close
  # and return the index of the first trading day with a close higher than the reference date. Should weed out losers
  # on a downward trend
  desc 'Placeholder to detect slopes of rvig and its signal'
  open_position :macd_confirm, :result => [:macd_hist] do |params|
    macd_hist = macdfix(:result => params[:result]).first
    pos_indexes = macd_hist.where { |e| e >= 0 }
    unless pos_indexes.nil?
      pos_hist = macd_hist[pos_indexes]
      hist_mean = pos_hist.mean
      hist_max = pos_hist.max
      hist_sd = pos_hist.sd(hist_mean)
      macd_hista = macd_hist.to_a
      (index = macd_hista.index { |val| val >= hist_mean }) ? adj_result_index(index) : nil
    else
      nil
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find where rvig crosses over rvig_signal returing the crossing with the max rgivor"
  exit_trigger :rvig_close, :time_period => 5, :result => [:rvigor, :rvigor_sig], :method => :crosses_over do |params|
    rvig, rvigSig = rvig(:result => params[:result])
    indexes = send(params[:method], rvigSig, rvig)
    hash = indexes.inject({}) { |hash, idx| hash[idx] = result_at(idx, :rvigor); hash }
    max = hash.values.max
    index = hash.invert[max]
#    tuples = slope_at_crossing(rvig, rvigSig, dn_crossings).select {  |tuple| tuple.last < 100.0 }
#    if dn_tuples.empty?
#      nil
#    else
#      [index2time(dn_tuples[0].first), :rvigor, dn_tuples[0].second]
#    end
    [index2time(index), :rvigor, max ]
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Just passes the exit triggers to the exit_strategy"
  close_position :pass_through, :result => [:identity] do |position, params|
  end

  #desc "Close the position if the stop loss is 15% or greater"
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
                       :order_by => 'tickers.symbol', :prefetch => 137, :postfetch => 45
       scan_vec << scan_name
     end
   end
  # For 2009, since it's incomplete we have to do compute the scan differently by...
  # ...find the lastest daily bar in the DB (using IBM as the guiney pig)
  # end date keeps advancing as long as their 30 trading days which is the max hold time
  desc "Population of all stocks with a minimum valume of 75000 for 2009"
  start_date = '1/1/2009'.to_date
  scan 'year_2009', :start_date => start_date, :end_date => start_date + 1.year - 1.day,
                    :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                    :conditions => liquid, :prefetch => 137, :postfetch => 45
  $scan_names << 'year_2009'
end

max_bar_date = DailyBar.maximum(:bardate, :conditions => { :ticker_id => 1674 }) #IBM

backtests(:generate_stats => false, :profile => false, :truncate => nil, :repopulate => false, :log_flags => [:basic],
          :days_to_open => 60, :days_to_close => 45, :populate => false, :epass => 0..0, :max_date => max_bar_date, :optimize_passes => false) do
  $scan_names.each do |scan_name|
    using(:rvig_open, :macd_confirm, :rvig_close, :pass_through, scan_name) do |entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan|
#      make_sheet(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan, :values => [:opening, :close, :high, :low, :volume], :pre_days => 1, :post_days => 30, :keep => true)
      #make_sheet(nil, nil, nil, nil, scan, :values => [:close], :pre_days => 1, :post_days => 30, :keep => true)
    end
  end
end

