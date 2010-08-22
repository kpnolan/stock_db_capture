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
# Table name: ann_inputs
#
#  id        :integer(4)      not null, primary key
#  o         :float
#  h         :float
#  l         :float
#  c         :float
#  rsi       :float
#  v         :integer(4)
#  rvig      :float
#  macd      :float
#  o0        :float
#  ticker_id :integer(4)
#  bartime   :datetime
#  o1        :float
#  o5        :float
#

class AnnInput < ActiveRecord::Base
  belongs_to :ticker

  class << self
    def populate(symbol, start_date, end_date)
      startd = start_date.to_date
      endd = end_date.to_date
      ts = Timeseries.new(symbol, startd..endd, 1.day)
      macd = ts.macdfix(:result => :macd_hist).to_a
      range = ts.index_range
      rsi = ts.rsi(:result => :array)
      rvig = ts.rvig(:result => :rvigor).to_a
      lengths = { :ts => ts.length, :macd => macd.length, :rsi => rsi.length, :rvig => rvig.length }
      lengths.inject({}) do |mem, pair|
        if mem == {}
          pair.last
        elsif mem != pair.last
          puts "#{pair.first} has len: #{pair.last}"
        else
          mem
        end
      end
      cols = %w{ bartime o h l c v rvig rsi macd }.map(&:to_sym)
      array_set = ts.timevec[range].zip(ts.opening[range].to_a, ts.high[range].to_a, ts.low[range].to_a, ts.close[range].to_a, ts.volume[range].to_a, rvig, rsi, macd)
      array_set.each do |row|
        attrs = cols.zip(row).inject({}) { |m, pair| m[pair.first] = pair.last; m}
        attrs[:v] = attrs[:v].to_i
        attrs[:ticker_id] = ts.ticker_id
        begin
          create!(attrs)
        rescue Exception => e
          debugger
        end
      end
      array_set.length
    end
  end
end

