# == Schema Information
# Schema version: 20091029212126
#
# Table name: intra_day_bars
#
#  id           :integer(4)      not null, primary key
#  ticker_id    :integer(4)
#  period       :integer(4)
#  bartime      :datetime
#  opening      :float
#  close        :float
#  high         :float
#  low          :float
#  volume       :integer(4)
#  accum_volume :integer(4)
#  delta        :float
#  seq          :integer(4)
#  bardate      :date
#

class IntraDayBar < ActiveRecord::Base

  COLUMN_ORDER = [:close, :high, :low, :opening, :volume, :bartime]

  belongs_to :ticker

  extend BarUtils
  extend TradingCalendar
  extend TableExtract
  extend Plot

  class << self

    def order ; 'bartime, id'; end
    def time_convert ; :to_time ;  end
    def time_class ; Time ;  end
    def time_res; 30.minutes; end

    def update(logger)
      end_date = latest_date()
      tuples = tickers_with_lagging_intraday(end_date)
      count = 1
      chunk = Splitter.new(tuples)
      for tuple in chunk
        symbol, max_date = tuple
        max_date = max_date.to_date
        td = trading_day_count(max_date, end_date)
        next if td.zero?
        start_date = max_date + 1.day
        begin
          logger.info "(#{chunk.id}) updating #{symbol}\t#{start_date}\t#{end_date}\t#{count} of #{chunk.length}"
          load_symbol(symbol, start_date, end_date)
        rescue Net::HTTPServerException => e
          if e.to_s.split.first == '400'
            ticker = Ticker.find_by_symbol(symbol)
            ticker.increment! :retry_count if ticker
            ticker.toggle! :active if ticker.retry_count == 12
          end
        rescue ActiveRecord::StatementInvalid => e
          logger.error("Duplicate symbol/time #{symbol} skipping...")
        rescue Exception => e
          logger.error("#{symbol}\t#{start_date}\t#{start_date} #{e.to_s}")
        end
        count += 1
      end
    end

    def load_symbol(symbol, start_date, end_date, resolution=30)
      @@qs ||= TdAmeritrade::QuoteServer.new()
      @period = resolution
      @accum_volume = 0
      @last_date = nil
      @last_close = 0.0
      @seq = 0
      bars = @@qs.intraday_for(symbol, start_date, end_date, resolution)
      bars.each { |bar| create_bar(symbol, bar) }
    end

    def create_bar(symbol, tda_bar_ary)
      bar = tda_bar_ary.dup
      ticker_id = Ticker.lookup(symbol).id
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift; h }
      attrs[:ticker_id] = ticker_id
      attrs[:volume] = attrs[:volume].to_i * 100
      attrs[:period] = @period
      attrs[:bardate] = attrs[:bartime].to_date

      if attrs[:bardate] == @last_date
        @accum_volume += attrs[:volume]
        attrs[:delta] = attrs[:close] - @last_close
        attrs[:accum_volume] = @accum_volume
      else
        @seq = 0
        @last_date= attrs[:bardate]
        @last_close = prior_close(ticker_id, @last_date)
        @accum_volume = attrs[:volume]
        attrs[:accum_volume] = @accum_volume
        attrs[:delta] = @last_close.nil? ? nil : attrs[:close] - @last_close
        @last_close = attrs[:close]
      end
      attrs[:seq] = @seq
      @seq += 1
      begin
        create! attrs
      rescue ActiveRecord::StatementInvalid => e
        if e.to_s =~ /Duplicate/
          raise e
        else
          puts "#{attrs[:date]}:#{e.to_s}"
        end
      rescue Exception => e
        puts "#{attrs[:date]}:#{e.to_s}"
      end
    end

    def prior_close(ticker_id, cur_date)
      last_daily_bar_date = trading_date_from(cur_date, -1)
      dc = DailyBar.find(:first, :conditions => [ 'ticker_id = ? AND bardate = ?', ticker_id, last_daily_bar_date])
      dc.nil? ? nil : dc.close
    end
  end
end
