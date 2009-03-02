backtest_scenario :five_day_max do

  self.ticker_population = Ticker.volume_above(20000)
  self.testing_period = date_range('01/01/2002', '12/31/2003')

  strategy :over_bought do
    crosses_over(high, indicator(:bband, :high_band)).each do |bar|
      trade(bar, :type => :sell_short, :price => :at_market, :bar => :next)
    end
  end

  strategy :over_sold do
    low.crosses_over(indicator(:bband, :low_band)).each do |bar|
      trade(bar, :type => :buy_long, :price => :at_market, :bar => +5)
    end
  end

  strategy :arron_buys do
    indicator(:adosc, :up).crosses_over(indicator(:adosc, :down)).each do |bar|
      trade(bar, :type => :buy_long, :price => :at_market, :bar => +2)
    end
  end

  strategy :intraday_by do
    zema_vec = indicator(:zema, :outZema)
    trend_vec = indicator(:ht_trendline, :outReal)
    for today in index_range
      yesterday = lambda { today - 1 }
      if zema[today] > trend_vec[today] and
          open[today] > open[yesterday.call] and
          high[today] > high[yesterday.call] and
          close[yesterday.call] > low[yesterday.call]+(high[yesterday.call]-low[yesterday.call]) / 3
        trade(today, :type => :buy_long)
      end
      if zema[today] < trend_vec[today] and
          open[today] < open[yesterday.call] and
          low[today] < low[yesterday.call] and
          close[yesterday.call] < high[yesterday.call] - (high[yesterday.call] - low[yesterday.call]) / 3
        trade(today, :type => :sell)
      end

      end
    end


end




