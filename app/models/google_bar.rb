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
# Schema version: 20100123024049
#
# Table name: google_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  opening   :float
#  close     :float
#  high      :float
#  volume    :integer(4)
#  low       :float
#  bartime   :datetime
#  bardate   :date
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

require 'date'

class GoogleBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a Yahoo request
  COLUMN_ORDER = [ :opening, :high, :low, :close, :volume ]

  belongs_to :ticker

  extend TableExtract
  extend BarUtils

  class << self

    def order ; 'bardate, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end
    def source_id; 'G'; end

    def load(logger)
      load_bars(logger, GoogleFinance::QuoteServer.new(:logger => logger), self.to_s.tableize)
    end

    def update(logger)
      update_bars(logger, GoogleFinance::QuoteServer.new(), self.to_s.tableize)
    end

    def create_bar(symbol, ticker_id, bar_ary)
      bar = bar_ary.dup
      datestr = bar.shift
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift.to_f; h }
      date = Date.parse(datestr)
      bartime = date.to_time.localtime.change(:hour => 6, :min => 30)
      attrs[:bartime] = bartime
      attrs[:bardate] = bartime.to_date
      attrs[:ticker_id] = ticker_id
      begin
        create! attrs
      rescue Exception => e
        puts "#{attrs[:bartime]}:#{e.to_s}"
      end
    end
  end
end
