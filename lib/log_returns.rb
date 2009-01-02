require 'retired_symbol_exception'

module LogReturns

  def ticker_ids
    DailyClose.connection.select_values('SELECT DISTINCT ticker_id FROM daily_closes WHERE r IS NULL ORDER BY ticker_id')
  end

  def update_returns()
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
    sql = "SELECT id, close from daily_closes where ticker_id = #{ticker_id} and r IS NOT NULL having max(date)"
    tuples = DailyClose.connection.select_rows(sql)
    if tuples.length != 1
      raise RetiredSymbolException.new(Ticker.find(ticker_id).symbol)
    else
      tuples
    end
  end

  def get_tuples(symbol, ticker_id)
    sql = "SELECT id, close from daily_closes where ticker_id = #{ticker_id} AND r is null order by date"
    tuples = DailyClose.connection.select_rows(sql)
    puts "computing #{tuples.length} returns for #{symbol}"
    tuples
  end
end
