require 'date'

module Scans
  def sample_population(size)
    sql = "SELECT symbol FROM daily_closes LEFT OUTER JOIN tickers ON tickers.id = ticker_id WHERE "+
          "symbol IS NOT NULL AND symbol NOT LIKE '^%' GROUP BY ticker_id ORDER BY AVG(volume) DESC LIMIT #{size}"
    @population ||= DailyClose.connection.select_values(sql)
  end

  def get_dates(num, dow)
    start = Date.today
    # find last dow
    while start.cwday != dow
      start -= 1
    end
    @ref_date = start
    puts "Ref Date: #{start}"
    dates = [ ]
    num.times { dates << start -= 7 }
    dates
  end

  def dates_selector(dates)
    dates.map { |d| "'#{d.to_s(:db)}'"}.join(', ')
  end

  def reference_value(symbol, dates)
    ticker_id = Ticker.find_by_symbol(symbol).id
    count = DailyClose.connection.select_value("select count(close) from daily_closes where ticker_id = #{ticker_id} and date in ( #{dates_selector(dates)} )").to_i
    if count < dates.length-3 #holiday?
      @logger.info("Rejected #{symbol} #{count} < #{dates.count}")
      nil
    else
      sql = "select avg(close) from daily_closes where ticker_id = #{ticker_id} and date in ( #{dates_selector(dates)} )"
      @ref_value = DailyClose.connection.select_value(sql).to_f
    end
  end

  def scan_type
    @scan_type ||= DerivedValueType.find_by_name('KirkRatioSP500')
  end

  def init
    @logger = ActiveSupport::BufferedLogger.new(File.join(RAILS_ROOT, 'log', 'kirk_ratio.log'))
  end

  def kirk_ratio
    init()
    date = Date.today
    dates = get_dates(26, 4)
    population = sample_population(2000)
    count = 0
    reference_close = reference_value('^GSPC', dates)
    for symbol in population
      ticker_id = Ticker.find_by_symbol(symbol).id
      begin
        current_close = DailyClose.first(:conditions => { :ticker_id => ticker_id, :date => @ref_date }).adj_close
        ratio = current_close / reference_close
        DerivedValue.create!(:derived_value_type => scan_type, :ticker_id => ticker_id,
                             :date => date, :time => date.to_time, :value => ratio)
        count += 1
      rescue Exception => e
        @logger.info("#{symbol}(#{ticker_id}): #{e.message}")
      end
    end
    count
  end
end
