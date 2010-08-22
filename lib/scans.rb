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

require 'date'

module Scans
  def sample_population(size)
    sql = "SELECT symbol FROM daily_bars LEFT OUTER JOIN tickers ON tickers.id = ticker_id WHERE "+
          "symbol IS NOT NULL AND symbol NOT LIKE '^%' GROUP BY ticker_id ORDER BY AVG(volume) DESC LIMIT #{size}"
    @population ||= DailyBar.connection.select_values(sql)
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
    count = DailyBar.connection.select_value("select count(close) from daily_bars where ticker_id = #{ticker_id} and date in ( #{dates_selector(dates)} )").to_i
    if count < dates.length-3 #holiday?
      @logger.info("Rejected #{symbol} #{count} < #{dates.count}")
      nil
    else
      sql = "select avg(close) from daily_bars where ticker_id = #{ticker_id} and date in ( #{dates_selector(dates)} )"
      @ref_value = DailyBar.connection.select_value(sql).to_f
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
        current_close = DailyBar.first(:conditions => { :ticker_id => ticker_id, :date => @ref_date }).adj_close
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
