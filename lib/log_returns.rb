module LogReturns

  def ticker_ids
    DailyClose.connection.select_values('select distinct ticker_id from daily_closes where daily_closes.return is null order by ticker_id')
  end

  def update_returns()
    ticker_ids.each do |tid|
      puts Ticker.find(tid).symbol
      next if (tuples = get_tuples(tid)).empty?
      tuples.unshift(get_last_close(tid).first)
      compute_returns(tuples)
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
      dc.update_attributes!(:return => r, :log_return => lr, :alr => alr)
    end
    nil
  end

  def get_last_close(ticker_id)
    sql = "SELECT id, close from daily_closes where ticker_id = #{ticker_id} and daily_closes.return IS NOT NULL having max(date)"
    tuples = DailyClose.connection.select_rows(sql)
  end

  def get_tuples(ticker_id)
    sql = "SELECT id, close from daily_closes where ticker_id = #{ticker_id} AND daily_closes.return is null order by date"
    tuples = DailyClose.connection.select_rows(sql)
  end
end
