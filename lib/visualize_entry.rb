# Copyright © Kevin P. Nolan 2009 All Rights Reserved.

module VisualizeEntry
  def graph_entry
    losers = Position.connection.select_rows("select id, nreturn*days_held from positions where nreturn < 0.0 order by nreturn")
    winners = Position.connection.select_rows("select id, nreturn*days_held from positions where nreturn > 0.0 order by nreturn desc")
    non_closed = Position.connection.select_rows("select id, nreturn*days_held from positions where nreturn is null")
    for i in 0..10000
    pair = case 1 #i%3
           when 0 : winners[i]
           when 1 : losers[i]
           when 2 : non_closed[i]
           end
      p = Position.find pair.first
      @ret = pair.last.nil? ? 'NULL' : pair.last.to_f * 100.0
      start_date = trading_days_from(p.entry_date, -20).last.to_date
      if p.exit_date
        exit_date = trading_days_from(p.exit_date, 10).last.to_date
      else
        exit_date = trading_days_from(p.entry_date, 20).last.to_date
      end
      symbol = Ticker.find(p.ticker_id).symbol
      ts(symbol, start_date..exit_date, 1.day, :pre_buffer => true, :post_buffer => 10)

      entry_index = $ts.time2index(p.entry_date, -1)
      @slope = $ts.linreg entry_index, :time_period => 10
      $ts.rsi :time_period => 14
      rvi_mem = $ts.rvi :time_period => 14, :result => :memo
      @rvi = rvi_mem.result_for(entry_index)
      break if quit?(p)
      system 'killall gnuplot'
    end
  end

  def quit?(p)
    exit_date = p.exit_date.nil? ? 'NULL' : p.exit_date.to_date.to_s
    exit_price = p.exit_price.nil? ? 'NULL' : p.exit_price
    nreturn = p.nreturn.nil? ? 'NULL' : p.nreturn * 100.0
    prompt = "#{p.entry_date.to_date.to_s}\t#{p.entry_price}\t#{exit_date.to_s}\t#{exit_price}\t#{nreturn}\t#{@rvi} > "
    print prompt
    resp = gets.strip
    resp == 'n' || resp == 'q'
  end
end
