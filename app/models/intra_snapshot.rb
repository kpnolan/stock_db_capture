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
# == Schema Information
# Schema version: 20100205165537
#
# Table name: intra_snapshots
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  interval  :integer(4)
#  snap_time :datetime
#  open      :float
#  close     :float
#  high      :float
#  low       :float
#  volume    :integer(4)
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class IntraSnapshot < ActiveRecord::Base
  COLUMN_ORDER = [:close, :high, :low, :opening, :volume, :start_time]
  HOURS_AT_3PM = 15

  belongs_to :ticker

  include TradingCalendar
  extend TableExtract
  extend Plot

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end

  class << self

    def order ; 'start_time, id'; end
    def time_class ; Time ;  end
    def time_res; 5.minutes; end

    def load_snapshots(symbol, start_date, end_date, resolution=30, snapshot_time=HOURS_AT_3PM)
      start_date = start_date.class == String ? Date.parse(start_date) : start_date
      end_date = end_date.class == String ? Date.parse(end_date) : end_date
      @@qs ||= TdAmeritrade::QuoteServer.new()
      @interval = resolution
      @accum_volume = 0
      @last_date = nil
      @snap_time = snapshot_time
      bars = @@qs.intraday_for(symbol, start_date, end_date, resolution)
      bars.each { |bar| create_snapshot(symbol, bar) }
    end

    def create_snapshot(symbol, tda_bar_ary)
      slice_time = tda_bar_ary[5].to_time
      if slice_time.to_date == @last_date
        @accum_volume += tda_bar_ary[4].to_i
        iif slice_time.hour == @snap_time
        bar = tda_bar_ary.dup
        ticker_id = Ticker.find_by_symbol(symbol).id
        attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift; h }
        attrs[:ticker_id] = ticker_id
        attrs[:interval] = @interval
        attrs[:snap_time] = slice_time
        begin
          create! attrs
        rescue Exception => e
          puts "#{attrs[:date]}:#{e.to_s}"
        end
      else
        @last_date= tda_bar_ary[5].to_date
        @accum_volume = tda_bar_ary[4].to_i
      end
    end
  end
end
