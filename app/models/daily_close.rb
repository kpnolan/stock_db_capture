# == Schema Information
# Schema version: 20090528012055
#
# Table name: daily_closes
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)      not null
#  date      :date
#  open      :float
#  close     :float
#  high      :float
#  low       :float
#  adj_close :float
#  volume    :integer(4)
#  week      :integer(4)
#  month     :integer(4)
#  r         :float
#  logr      :float
#  alr       :float
#

class DailyClose < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Plot

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end

  class << self

    def order ; 'date, id'; end
    def time_col ; :date ;  end
    def time_convert ; :to_date ;  end
    def time_class ; Date ;  end
    def time_res; 1; end

    def catchup_to_date(date=nil)
      date = date.nil? ? Date.today : date
      sql = "select ticker_id, symbol, max(date) as max from daily_closes " +
        "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
      self.connection.select_rows(sql)
    end

    def avg_volume(from, to)
      @volumes ||= DailyClose.connection.select_values("SELECT avg(volume) from daily_closes "+
                                                       "WHERE date >= '#{from.to_s(:db)}' AND date <= '#{to.to_s(:db)}'"+
                                                       'GROUP BY ticker_id ORDER BY avg(volume)')
      @volumes.map { |vstr| vstr.to_f.round }
    end

    def max_between(column, ticker_id, date_range)
      sdate = date_range.begin.to_date.to_s(:db)
      edate = date_range.end.to_date.to_s(:db)
      max_value = connection.select_value("SELECT (@m := MAX(#{column})) from daily_closes WHERE ticker_id = #{ticker_id} AND " +
                                          "date BETWEEN '#{sdate}' AND '#{edate}'").to_f
      #max_value = maximum(column.to_sym, :conditions => { :ticker_id => ticker_id, :date => date_range })
      #at_date = first(:conditions => { :ticker_id => ticker_id, column.to_sym => max_value, :date => date_range })

      m = connection.select_value("SELECT @m")
      at_date = connection.select_value("SELECT date from daily_closes WHERE ticker_id = #{ticker_id} AND #{column} = @m " +
                                        "and date BETWEEN '#{sdate}' AND '#{edate}'")
      at_date = Date.parse(at_date)
      [max_value, at_date ]
    end
  end
end

