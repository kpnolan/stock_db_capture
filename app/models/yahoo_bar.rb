# == Schema Information
# Schema version: 20091016185148
#
# Table name: yahoo_bars
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
#  adj_close :float
#  bardate   :date
#

require 'date'

class YahooBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a Yahoo request
  COLUMN_ORDER = [ :opening, :high, :low, :close, :volume, :adj_close ]

  belongs_to :ticker

  extend TableExtract

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def time(); date; end

  class << self

    def order ; 'date, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end

    def find_loss(ticker_id, entry_date, exit_date, ratio)
      sql = "select date(bartime), high, low from yahoo_bars where date between '#{entry_date.to_s(:db)}' and '#{exit_date.to_s(:db)}' "+
            "and ticker_id = #{ticker_id} group by date having ((high - low) / high) > #{ratio} order by bartime"
      rows = connection.select_rows(sql)
    end

    def load_history(symbol, start_date, end_date)
      start_date = start_date.class == String ? Date.parse(start_date) : start_date
      end_date = end_date.class == String ? Date.parse(end_date) : end_date
      @@qs ||= YahooFinance::QuoteServer.new()
      bars = @@qs.dailys_for(symbol, start_date, end_date)
      bars.each { |bar| create_bar(symbol, bar) }
    end

    def create_bar(symbol, ticker_id, bar_ary)
      bar = bar_ary.dup
      datestr = bar.shift
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift.to_f; h }
      date = Date.parse(datestr)
      bartime = date.to_time.localtime.change(:hour => 6, :min => 30)
      attrs[:bartime] = bartime
      attrs[:bardate] = bartime.to_date
      attrs[:ticker_id] = ticker_id
      begin
        create! attrs
      rescue Exception => e
        puts "#{attrs[:bartime]}:#{e.to_s}"
      end
    end

    def catchup_to_date(date=nil)
      date = date.nil? ? Date.today : date
      sql = "select ticker_id, symbol, max(date(bartime)) as max from yahoo_bars " +
        "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
      self.connection.select_rows(sql)
    end

    def avg_volume(from, to)
      @volumes ||= DailyBar.connection.select_values("SELECT avg(volume) from yahoo_bars "+
                                                     "WHERE date(bartime) BETWEEN '#{from.to_s(:db)}' AND '#{to.to_s(:db)}'"+
                                                     'GROUP BY ticker_id ORDER BY avg(volume)')
      @volumes.map { |vstr| vstr.to_f.round }
    end

    def max_between(column, ticker_id, date_range)
      sdate = date_range.begin.to_date.to_s(:db)
      edate = date_range.end.to_date.to_s(:db)
      max_value = connection.select_value("SELECT (@m := MAX(#{column})) from yahoo_bars WHERE ticker_id = #{ticker_id} AND " +
                                          "date(bartime) BETWEEN '#{sdate}' AND '#{edate}'").to_f
      #max_value = maximum(column.to_sym, :conditions => { :ticker_id => ticker_id, :date => date_range })
      #at_date = first(:conditions => { :ticker_id => ticker_id, column.to_sym => max_value, :date => date_range })

      m = connection.select_value("SELECT @m")
      at_date = connection.select_value("SELECT date(bartime) as date from yahoo_bars WHERE ticker_id = #{ticker_id} AND #{column} = @m " +
                                        "and date BETWEEN '#{sdate}' AND '#{edate}'")
      at_date = Date.parse(at_date)
      [max_value, at_date ]
    end
  end
end
