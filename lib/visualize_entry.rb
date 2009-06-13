module VisualizeEntry
  def graph_entry
    for p in Position.all
      start_date = trading_days_from(p.entry_date, 20, -1).last.to_date
      end_date = trading_days_from(p.entry_date, 20).last.to_date
      symbol = Ticker.find(p.ticker_id).symbol
      ts(symbol, start_date..end_date, 1.day)
      $ts.rsi :time_period => 5
      $ts.multi_calc [:zema, :ema], :time_period => 5
      $ts.rvig
      $ts.rvi
      break if quit?(p)
      system 'killall gnuplot'
    end
  end
  def quit?(p)
    print "entry dt: #{p.entry_date.to_date.to_s(:short)} continue? Y/n > "
    resp = gets.strip
    resp == 'n' || resp == 'q'
  end
end
