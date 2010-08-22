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
  desc "Find all places where RSI gooes heads upwards of 30"
  entry_trigger :rsi_open_14, :time_period => 14, :result => [:rsi] do |params, pass|
    rsi_vec = rsi(params).first
    indexes = under_threshold(20+pass*5, rsi_vec)
  end

  #-----------------------------------------------------------------------------------------------------------------
  # This block just passes through the entry trigger recorded in the previous step. No addiional filtering is involved.
  desc 'Just use the value of the entry trigger'
  open_position :entry_trigger_passthrough, :result => [:identity] do |params|
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Find all places where RSI crosses 50 from below"
  exit_trigger :rsi_rvi_50, :time_period => 14, :result => :first do |params|
    min_time, meth = close_under_min(:rsi => params.merge(:threshold => 50),
                                     :rvi => params.merge(:threshold => 50))
    [min_time, meth, result_at(min_time, meth)]
  end

  #-----------------------------------------------------------------------------------------------------------------
  desc "Close positions that have been triggered from an RVI or and RSI and whose indicatars have continued to climb until they peak out or level out"
  close_position :lagged_rsi_difference, :time_period => 14, :result => [:rsi] do |position, params|
    rsi_ary = rsi(params).to_a
    exit_rsi = rsi_ary.shift
    index = monotonic_sequence(exit_rsi, rsi_ary)
    index = (index == :max ? index_range.end : [index_range.begin, index-1].max)
    exit_date, exit_price = closing_values_at(index)
    if exit_date < position.xttime
      debugger
    end
    index
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
                       :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:rsi, 14),
                       :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                       :order_by => 'tickers.symbol'
       scan_vec << scan_name
     end
   end
  # For 2009, since it's incomplete we have to do compute the scan differently by...
  # ...find the lastest daily bar in the DB (using IBM as the guiney pig)
  latest_bar_date = DailyBar.maximum(:bartime, :include => :ticker, :conditions => "tickers.symbol = 'IBM'" ).to_date
  # end date keeps advancing as long as their 30 trading days which is the max hold time
  end_date = latest_bar_date
  desc "Population of all stocks with a minimum valume of 100000 from 2009-1-1 to #{end_date}"
  scan 'year_2009', :start_date => '1/1/2009', :end_date => '12/23/2009',
                    :join => 'LEFT OUTER JOIN tickers ON tickers.id = ticker_id',
                    :order => 'tickers.symbol',
                    :conditions => liquid, :prefetch => Timeseries.prefetch_bars(:rsi, 14), :postfetch => 0
  $scan_names << 'year_2009'
end

backtests(:generate_stats => false, :profile => false, :truncate => :scan, :repopulate => true, :log_flags => [:basic],
           :prefetch => Timeseries.prefetch_bars(:rsi, 14), :postfetch => 20, :days_to_close => 20, :populate => true) do
  $scan_names.each do |scan_name|
    using(:rsi_open_14, :entry_trigger_passthrough, :rsi_rvi_50, :lagged_rsi_difference, scan_name) do |entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan|
#      make_sheet(entry_trigger, entry_strategy, exit_trigger, exit_strategy, scan, :values => [:opening, :close, :high, :low, :volume], :pre_days => 1, :post_days => 30, :keep => true)
      #make_sheet(nil, nil, nil, nil, scan, :values => [:close], :pre_days => 1, :post_days => 30, :keep => true)
    end
  end
end

