# == Schema Information
# Schema version: 20091016185148
#
# Table name: google_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)
#  opening   :float
#  close     :float
#  high      :float
#  volume    :integer(4)
#  low       :float
#  bartime   :datetime
#  bardate   :date
#

require 'date'

class GoogleBar < ActiveRecord::Base

  # this is the order of the data fields returned from TDAmeritrade for a Yahoo request
  COLUMN_ORDER = [ :opening, :high, :low, :close, :volume ]

  belongs_to :ticker

  extend TableExtract
  extend BarUtils

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def time(); date; end

  class << self

    def order ; 'date, id'; end
    def time_convert ; 'to_time' ;  end
    def time_class ; Time ;  end
    def time_res; 1.day; end
    def source_id; 'G'; end

    def load(logger)
      load_bars(logger, GoogleFinance::QuoteServer.new(:logger => logger), self.to_s.tableize)
    end

    def update(logger)
      update_bars(logger, GoogleFinance::QuoteServer.new(), self.to_s.tableize)
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
      sql = "select ticker_id, symbol, max(date(bartime)) as max from google_bars " +
        "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
      self.connection.select_rows(sql)
    end

    def avg_volume(from, to)
      @volumes ||= DailyBar.connection.select_values("SELECT avg(volume) from google_bars "+
                                                     "WHERE date(bartime) BETWEEN '#{from.to_s(:db)}' AND '#{to.to_s(:db)}'"+
                                                     'GROUP BY ticker_id ORDER BY avg(volume)')
      @volumes.map { |vstr| vstr.to_f.round }
    end

    def max_between(column, ticker_id, date_range)
      sdate = date_range.begin.to_date.to_s(:db)
      edate = date_range.end.to_date.to_s(:db)
      max_value = connection.select_value("SELECT (@m := MAX(#{column})) from google_bars WHERE ticker_id = #{ticker_id} AND " +
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
