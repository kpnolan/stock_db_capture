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
# Table name: splits
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)
#  date       :date
#  from       :integer(4)
#  to         :integer(4)
#  created_on :date
#

# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

class Split < ActiveRecord::Base
  belongs_to :ticker

  extend BarUtils

  class << self
    def load(logger)
      ticker_ids = Ticker.find(:all, :conditions => "symbol not like '%-%'").map(&:id)
      chunk = BarUtils::Splitter.new(ticker_ids)
      count = 0
      for ticker_id in chunk do
        ticker = Ticker.find ticker_id
        symbol = ticker.symbol
        cnt = load_from_ticker_id(ticker_id, :logger => logger)
        count += 1
        logger.info "(#{chunk.id}) loaded #{cnt} splits for #{symbol}\t#{count} of #{chunk.length}"
      end
    end

    def load_from_ticker_id(ticker_id, options={})
      symbol = Ticker.find(ticker_id).symbol
      sp = YahooFinance::SplitParser.new(symbol, options)
      split_vec = sp.splits()
      count = 0
      split_vec.each do |split|
        begin
          next unless find(:first, :conditions => { :ticker_id => ticker_id, :date => split[:date] }).nil?
          create! split.merge!(:ticker_id => ticker_id, :created_on => Date.today)
        rescue Exception => e
          logger.error("#{e.class}: #{e.to_s}")
          retry
        end
        count += 1
      end
      count
    end
  end
end
