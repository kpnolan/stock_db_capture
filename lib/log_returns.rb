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

require 'rubygems'
require 'narray'
require 'retired_symbol_exception'


module LogReturns

  attr_reader :logger, :year, :last_date
  attr_accessor :count, :counter

  Infinity = 1.0/0.0
  MinusInfinity = -1.0/0.0

  def ticker_ids(year=nil)
    if year.nil?
      @rnulls ||= DailyBar.connection.select_values('SELECT DISTINCT ticker_id FROM daily_bars LEFT OUTER JOIN tickers on tickers.id = ticker_id WHERE logr IS NULL ORDER BY symbol')
    else
      @rnulls ||= DailyBar.connection.select_values("SELECT DISTINCT ticker_id FROM daily_bars LEFT OUTER JOIN tickers on tickers.id = ticker_id WHERE date BETWEEN '#{year}0101' and '#{year}1231' ORDER BY symbol")
    end
  end

  def all_ticker_ids
    Ticker.ids
  end

  # This method computes the return, log return, and anunalized_returns for all returns for a given
  # ticker at once using vector math, so it's very fast
  def initialize_returns(logger)
    year_env = ENV['YEAR']
    @year = year_env.to_i if year_env
    @logger = logger
    @counter = 1
    @count = ticker_ids(year).length
    for ticker_id in ticker_ids()
        ticker = Ticker.transaction do
          ticker = Ticker.find_by_id(ticker_id, :lock => true)
          next if ticker.locked
          ticker.locked = true
          ticker.save!
          ticker
        end
        next if ticker.nil?
      begin
        symbol = ticker.symbol
        compute_vectors_and_update(symbol, ticker_id) unless year
        compute_vectors_and_update(symbol, ticker_id, Date.civil(year,1,1)..Date.civil(year,12,31)) if year
        self.counter += 1
      rescue Exception => e
        puts e.message
      end
    end
  end

  # This method is used to compute the return, log return, and anunalized_returns on a frequent (daily) basis
  # It does not employ an vector math since where only dealing with one return at a time
  def update_returns(logger)
    self.logger = logger
    ticker_ids.each do |tid|
      symbol = Ticker.find(tid).symbol
      next if (tuples = get_tuples(symbol, tid)).empty?
      begin
        tuples.unshift(get_last_close(tid).first)
        compute_returns(tuples)
      rescue RetiredSymbolException => e
        tuples.unshift(tuples.first)
        compute_returns(tuples)
      end
    end
    ticker_ids.length
  end

  def compute_returns(tuples)
    return if tuples.empty?

    len = tuples.length

    1.upto(len-1) do |i|
      curval = tuples[i].second.to_f
      preval = tuples[i-1].second.to_f
      if preval == 0.0 || curval == 0
        lr = 0.0
      else
        lr = Math.log(curval/preval)
      end
      dc = DailyBar.find tuples[i].first
      dc.update_attributes!(:logr => lr)
    end
    nil
  end

  def get_last_close(ticker_id)
    sql = "SELECT id, close from daily_bars where ticker_id = #{ticker_id} and r IS NOT NULL having max(date)"
    tuples = DailyBar.connection.select_rows(sql)
    if tuples.length != 1
      raise RetiredSymbolException.new(Ticker.find(ticker_id).symbol)
    else
      tuples
    end
  end

  def get_tuples(symbol, ticker_id)
    sql = "SELECT id, close from daily_bars where ticker_id = #{ticker_id} AND logr is null order by date"
    tuples = DailyBar.connection.select_rows(sql)
    logger.info("computing #{tuples.length} returns for #{symbol}")
    tuples
  end

  # This function replaces
  def compute_vectors_and_update(symbol, ticker_id, date_range=nil)
    conditions = date_range.nil? ? { } : { :date => date_range }
    recs = DailyBar.find_all_by_ticker_id(ticker_id, :conditions => conditions, :order => 'date')

    logger.info("computing #{recs.length} returns for #{symbol} (#{counter} out of #{count})")

    close_vec = recs.map { |rec| rec.close }
    close_vec1 = close_vec.dup

    prev_bar = nil
    if date_range
      prev_date = trading_date_from(date_range.begin, -1)
      prev_bar = DailyBar.find_by_ticker_id_and_date(ticker_id, prev_date)
    end
    close_vec1.unshift(prev_bar ? prev_bar.close : close_vec.first)
    close_vec.push(close_vec.last)

    # compute returns by duplicating the adjusted_close vector and shifting it right one
    nshifted_vec = NArray.to_na(close_vec1)
    nclose_vec = NArray.to_na(close_vec)

    # now, in one fell swoop we divide the original vector by the one shifted right
    # so we get adj_close/prev_adj_close in all elements
    nr_vec = nclose_vec / nshifted_vec
    nlogr_vec = NMath.log(nr_vec)
    # now is just a matter of updating the DailyBar records with the new values
    index = 0
    for rec in recs
        begin
          rec.update_attribute(:logr, nlogr_vec[index])
        rescue Exception => e
          self.logger.error("#{e.message} for #{ticker_id} at index: #{index}") unless e.to_s =~ /Infinity/
          rec.update_attribute(:logr, 0.0)
        else
      end
      index += 1
    end
  end
end
