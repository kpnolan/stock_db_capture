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
# Table name: rsi_target_studies
#
#  id                   :integer(4)      not null, primary key
#  ticker_id            :integer(4)
#  start_date           :date
#  end_date             :date
#  delta_price          :float
#  slope                :float
#  chisq                :float
#  target_rsi           :float
#  prior_price          :float
#  last_price           :float
#  pos_delta            :float
#  neg_delta            :float
#  pos_delta_plus       :float
#  neg_delta_plus       :float
#  pos_delta_plus_ratio :float
#  neg_delta_plus_ratio :float
#  prior_rsi            :float
#  delta_rsi            :float
#

require 'ostruct'

class RsiTargetStudy < ActiveRecord::Base
  belongs_to :ticker

  extend TradingCalendar
  extend BarUtils

  class << self
    def generate(logger)
      ticker_ids = tickers_with_some_history()
      max = ticker_ids.length
      start_date = end_date = self.trading_date_from(Date.today, -1)
      exp_date = self.trading_date_from(start_date, -1)
      chunk = Splitter.new(ticker_ids)
      count = 0
      for ticker_id in chunk do
        ticker = Ticker.find(ticker_id)
        symbol = ticker.symbol
        next if symbol.nil?
        begin
          logger.info "(#{chunk.id}) loading #{symbol}\t#{count} of #{chunk.length}"
          ts1 = Timeseries.new(symbol, start_date..end_date, 1.day)
          ts2 = Timeseries.new(symbol, exp_date..exp_date, 1.day)
          target_rsi = ts1.rsi(:result => :last)
          prior_rsi = ts2.rsi(:result => :last)
          target_price = ts1.close[-1]
          last_price = prior_price = ts1.close[-2]
          slope, chisq = ts1.lrclose()
          price_delta = target_price - last_price
          pos_delta, neg_delta = ts2.invrsi_exp(:rsi => target_rsi)
          os = OpenStruct.new({ :start_date => start_date, :end_date => end_date,
                                :target_rsi => target_rsi, :prior_rsi => prior_rsi, :delta_rsi => target_rsi - prior_rsi,
                                :last_price => target_price, :slope => slope, :chisq => chisq, :delta_price => price_delta,
                                :ticker_id => ticker_id, :pos_delta => pos_delta, :neg_delta => neg_delta})

          target_prices = {
            :pos_delta_plus =>     last_price+pos_delta,
            :neg_delta_plus =>     last_price+neg_delta,
          }

          target_prices.each_pair do |k,v|
            os.new_ostruct_member(k)
            os.send("#{k}=",v)
          end

          ratios = { }
          target_prices.each_pair do |k,v|
            r = (last_price - v)/last_price
            os.new_ostruct_member("#{k}_ratio")
            os.send("#{k}_ratio=",r)
          end

          attrs = os.marshal_dump
          attrs.each_pair { |k,v| attrs[k] = nil if (v.is_a?(Float) && (v.nan? || v.infinite? == 1 || v.infinite? == -1)) }
          create!(attrs)

        rescue TimeseriesException => e
          logger.error(e.to_s)
        end
        count += 1
      end
    end
  end
end
