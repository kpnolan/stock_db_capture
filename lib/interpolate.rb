require 'faster_csv'

module Interpolate

  extend TradingCalendar
  include Predict

  BAR_VALUES = [:opening, :high, :low, :close, :volume]

  def interpolate_date(ticker_id, bartime)
    xvec = [2, 0]
    day_before = Interpolate.trading_date_from(bartime, -1)
    day_after = Interpolate.trading_date_from(bartime, 1).end_of_day
    bars = DailyBar.all(:conditions => { :ticker_id => ticker_id, :bartime => day_before..day_after}, :include => :ticker, :order => 'tickers.symbol' )
    if bars.length == 1
      puts "#{Ticker.find(ticker_id).symbol} only has on point"
    elsif bars.length == 3
      puts "#{Ticker.find(ticker_id).symbol} only has 3 points, middle: #{bars[1].bartime}"
      return
    end
    symbol = bars.first.ticker.symbol
    bar_hash = { }
    est_hash = { }
    BAR_VALUES.each do |slot|
      bar_hash[slot] = []
      bars.each do |bar|
        bar_hash[slot] << bar.send(slot)
      end
      est_hash[slot] = linear(xvec, bar_hash[slot], 1).first
    end
    attrs = est_hash.merge(:ticker_id => ticker_id, :bartime => bartime, :interpolated => true)
    puts "#{@counter} #{symbol}"
    @counter += 1
    begin
      DailyBar.create!(attrs)
    rescue
      puts 'DUP'
    end
  end

  def verify_missing_date(ticker, bartime)
    db = DailyBar.first(:conditions => { :ticker_id => ticker.id, :bartime => bartime })
    if db.nil?
      puts "#{ticker.symbol} date missing"
    else
      puts "#{ticker.symbol} NOT date missing"
    end
  end

  def ticker_loop
    #tickers_ids = DailyBar.connection.select_values("select ticker_id from tickerids").map(&:to_i)
    date = Time.local(2007, 9, 14, 6, 30)
    symbols = read_symbols()
    tickers = symbols.map { |symbol| Ticker.lookup(symbol) }
    tickers.each { |ticker| verify_missing_date(ticker, date) }
    exit
    @counter = 1
    tickers.each do |ticker|
      interpolate_date(ticker.id, date)
    end
    nil
  end

  def read_symbols()
    symbols = FasterCSV.read(File.join(RAILS_ROOT, 'tmp', 'missing_date.csv')).map(&:first).sort
  end
end


