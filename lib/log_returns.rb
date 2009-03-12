require 'rubygems'
require 'narray'
require 'retired_symbol_exception'


module LogReturns

  attr_accessor :logger, :counter, :count

  Infinity = 1.0/0.0
  MinusInfinity = -1.0/0.0

  def ticker_ids
    DailyClose.connection.select_values('SELECT DISTINCT ticker_id FROM daily_closes LEFT OUTER JOIN tickers on tickers.id = ticker_id WHERE active = 1 and r IS NULL ORDER BY symbol')
  end

  def all_ticker_ids
    Ticker.ids
  end

  # This method computes the return, log return, and anunalized_returns for all returns for a given
  # ticker at once using vector math, so it's very fast
  def initialize_returns(logger)
    self.logger = logger
    self.counter = 1
    self.count = Ticker.active_ids.length
    for ticker_id in Ticker.active_ids
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
        compute_vectors_and_update(symbol, ticker_id)
        self.counter += 1
      rescue => e
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
        r, lr, alr = 1.0, 0.0, 0.0
      else
        r = (curval/preval)
        lr = Math.log(r)
        alr = lr*252.0
      end
      dc = DailyClose.find tuples[i].first
      dc.update_attributes!(:r => r, :logr => lr, :alr => alr)
    end
    nil
  end

  def get_last_close(ticker_id)
    sql = "SELECT id, adj_close from daily_closes where ticker_id = #{ticker_id} and r IS NOT NULL having max(date)"
    tuples = DailyClose.connection.select_rows(sql)
    if tuples.length != 1
      raise RetiredSymbolException.new(Ticker.find(ticker_id).symbol)
    else
      tuples
    end
  end

  def get_tuples(symbol, ticker_id)
    sql = "SELECT id, adj_close from daily_closes where ticker_id = #{ticker_id} AND r is null order by date"
    tuples = DailyClose.connection.select_rows(sql)
    logger.info("computing #{tuples.length} returns for #{symbol}")
    tuples
  end

  # This function replaces
  def compute_vectors_and_update(symbol, ticker_id)
    recs = DailyClose.find_all_by_ticker_id(ticker_id, :order => 'date')

    logger.info("computing #{recs.length} returns for #{symbol} (#{counter} out of #{count})")

    close_vec = recs.map { |rec| rec.adj_close }
    close_vec1 = close_vec.dup
    close_vec1.unshift(close_vec.first)
    close_vec.push(close_vec.last)

    # compute returns by duplicating the adjusted_close vector and shifting it right one
    nshifted_vec = NArray.to_na(close_vec1)
    nclose_vec = NArray.to_na(close_vec)

    # now, in one fell swoop we divide the original vector by the one shifted right
    # so we get adj_close/prev_adj_close in all elements
    nr_vec = nclose_vec / nshifted_vec
    nlogr_vec = NMath.log(nr_vec)
    nalr_vec = nlogr_vec*252.0

    # now is just a matter of updating the DailyClose records with the new values
    index = 0
    for rec in recs
        begin
          rec.update_attributes!(:r => nr_vec[index], :logr => nlogr_vec[index], :alr => nalr_vec[index])
        rescue => e
          self.logger.error("#{e.message} for #{ticker_id} at index: #{index}")
          rec.update_attributes!(:r => 1.0, :logr => 0.0, :alr => 0.0)
        else
      end
      index += 1
    end
  end
end
