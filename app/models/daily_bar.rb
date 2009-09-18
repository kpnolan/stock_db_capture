# == Schema Information
# Schema version: 20090916020242
#
# Table name: daily_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  opening   :float
#  close     :float
#  high      :float
#  volume    :integer(4)
#  logr      :float
#  low       :float
#  bartime   :datetime
#

require 'date'

class DailyBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a PriceHistory request
  COLUMN_ORDER = [:close, :high, :low, :opening, :volume, :bartime]

  belongs_to :ticker

  extend TableExtract
  extend Plot

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def time(); date; end

  class << self

    def order ; 'date, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end

    def find_loss(ticker_id, entry_date, exit_date, ratio)
      sql = "select date(bartime), high, low from daily_bars where date between '#{entry_date.to_s(:db)}' and '#{exit_date.to_s(:db)}' "+
            "and ticker_id = #{ticker_id} group by date having ((high - low) / high) > #{ratio} order by bartime"
      rows = connection.select_rows(sql)
    end

    def load_tda_history(symbol, start_date, end_date)
      start_date = start_date.class == String ? Date.parse(start_date) : start_date
      end_date = end_date.class == String ? Date.parse(end_date) : end_date
      @@qs ||= TdAmeritrade::QuoteServer.new()
      bars = @@qs.dailys_for(symbol, start_date, end_date)
      bars.each { |bar| create_bar(symbol, bar) }
    end

    def create_bar(symbol, tda_bar_ary)
      bar = tda_bar_ary.dup
      ticker_id = Ticker.find_by_symbol(symbol).id
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift; h }
      attrs[:ticker_id] = ticker_id
      attrs[:volume] = attrs[:volume].to_i
      attrs[:bartime] = attrs[:bartime].change(:hour => 6, :min => 30)
      begin
        create! attrs
      rescue Exception => e
        puts "#{attrs[:date]}:#{e.to_s}"
      end
    end

    def catchup_to_date(date=nil)
      date = date.nil? ? Date.today : date
      sql = "select ticker_id, symbol, max(date(bartime)) as max from daily_bars " +
        "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
      self.connection.select_rows(sql)
    end

    def avg_volume(from, to)
      @volumes ||= DailyBar.connection.select_values("SELECT avg(volume) from daily_bars "+
                                                     "WHERE date(bartime) BETWEEN '#{from.to_s(:db)}' AND '#{to.to_s(:db)}'"+
                                                     'GROUP BY ticker_id ORDER BY avg(volume)')
      @volumes.map { |vstr| vstr.to_f.round }
    end

    def max_between(column, ticker_id, date_range)
      sdate = date_range.begin.to_date.to_s(:db)
      edate = date_range.end.to_date.to_s(:db)
      max_value = connection.select_value("SELECT (@m := MAX(#{column})) from daily_bars WHERE ticker_id = #{ticker_id} AND " +
                                          "date(bartime) BETWEEN '#{sdate}' AND '#{edate}'").to_f
      #max_value = maximum(column.to_sym, :conditions => { :ticker_id => ticker_id, :date => date_range })
      #at_date = first(:conditions => { :ticker_id => ticker_id, column.to_sym => max_value, :date => date_range })

      m = connection.select_value("SELECT @m")
      at_date = connection.select_value("SELECT date(bartime) as date from daily_bars WHERE ticker_id = #{ticker_id} AND #{column} = @m " +
                                        "and date BETWEEN '#{sdate}' AND '#{edate}'")
      at_date = Date.parse(at_date)
      [max_value, at_date ]
    end
  end
end
