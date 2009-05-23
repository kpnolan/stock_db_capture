# == Schema Information
# Schema version: 20090522155818
#
# Table name: daily_bars
#
#  id        :integer(4)      not null, primary key
#  ticker_id :integer(4)      not null
#  date      :date
#  open      :float
#  close     :float
#  high      :float
#  low       :float
#  volume    :integer(4)
#  r         :float
#  logr      :float
#
require 'rubygems'
require 'ruby-debug'
class DailyBar < ActiveRecord::Base

  COLUMN_ORDER = [:close, :high, :low, :open, :volume, :date]
  belongs_to :ticker

  schema_validations :only => :ticker_id

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

    def load_tda_history(symbol, start_date, end_date)
      @@qs ||= TdAmeritrade::QuoteServer.new()
      bars = @@qs.dailys_for(symbol, Date.parse(start_date), Date.parse(end_date))
      bars.each { |bar| create_bar(symbol, bar) }
    end

    def create_bar(symbol, tda_bar_ary)
      bar = tda_bar_ary.dup
      ticker_id = Ticker.find_by_symbol(symbol).id
      attrs = COLUMN_ORDER.inject({}) { |h, col| h[col] = bar.shift; h }
      attrs[:ticker_id] = ticker_id
      attrs[:volume] = attrs[:volume].to_i
      attrs[:date] = attrs[:date].to_date
      begin
        create! attrs
      rescue Exception => e
        puts "#{attrs[:date]}:#{e.to_s}"
      end
    end

    def catchup_to_date(date=nil)
      date = date.nil? ? Date.today : date
      sql = "select ticker_id, symbol, max(date) as max from daily_bars " +
        "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
      self.connection.select_rows(sql)
    end

    def avg_volume(from, to)
      @volumes ||= DailyBar.connection.select_values("SELECT avg(volume) from daily_bars "+
                                                     "WHERE date >= '#{from.to_s(:db)}' AND date <= '#{to.to_s(:db)}'"+
                                                     'GROUP BY ticker_id ORDER BY avg(volume)')
      @volumes.map { |vstr| vstr.to_f.round }
    end

    def max_between(column, ticker_id, date_range)
      sdate = date_range.begin.to_date.to_s(:db)
      edate = date_range.end.to_date.to_s(:db)
      max_value = connection.select_value("SELECT (@m := MAX(#{column})) from daily_bars WHERE ticker_id = #{ticker_id} AND " +
                                          "date BETWEEN '#{sdate}' AND '#{edate}'").to_f
      #max_value = maximum(column.to_sym, :conditions => { :ticker_id => ticker_id, :date => date_range })
      #at_date = first(:conditions => { :ticker_id => ticker_id, column.to_sym => max_value, :date => date_range })

      m = connection.select_value("SELECT @m")
      at_date = connection.select_value("SELECT date from daily_bars WHERE ticker_id = #{ticker_id} AND #{column} = @m " +
                                        "and date BETWEEN '#{sdate}' AND '#{edate}'")
      at_date = Date.parse(at_date)
      [max_value, at_date ]
    end
  end
end

