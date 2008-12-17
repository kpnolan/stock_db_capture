module LogReturns

  def symbols
    Ticker.connection.select_values('select symbol from tickers order by symbol')
  end

  def update_returns
    symbols.each do |symbol|
      ids, closes = get_vectors(symbol)
      compute_returns(ids, closes)
      puts symbol
    end
  end

  def compute_returns(idvec, cvec)
    return if idvec == []

    rvec = Array.new(252)
    lrvec = Array.new(252)
    arvec = Array.new(252)

    1.upto(cvec.length-1) do |i|
      r = (cvec[i].to_f/cvec[i-1].to_f)
      lr = Math.log(r)
      ar = lr*252.0
      rvec[i] = r
      lrvec[i] = lr
      arvec[i] = ar
      rvec[0] = 1
      lrvec[0] = arvec[0] = 0
    end
    idvec.each do |id|
      obj = DailyClose.find id
      obj.update_attributes!(:return => rvec.shift, :log_return => lrvec.shift, :alr => arvec.shift)
    end
    nil
  end

  def get_vectors(symbol)
    sql1 = "SELECT close from daily_closes join tickers on tickers.id = ticker_id where symbol = '#{symbol}' order by date"
    sql2 = "SELECT daily_closes.id from daily_closes join tickers on tickers.id = ticker_id where symbol = '#{symbol}' order by date"
    close_vec = DailyReturn.connection.select_values(sql1)
    id_vec = DailyReturn.connection.select_values(sql2)
    [id_vec, close_vec]
  end

end
