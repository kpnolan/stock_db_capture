# == Schema Information
# Schema version: 20080813192644
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
#

class DailyClose < ActiveRecord::Base
  belongs_to :ticker

  ATTRS = [ :close, :open, :high, :low, :adj_close, :volume, :date, :return, :log_return, :alr ]

  extend TableExtract

  def self.order
    'date'
  end

  def self.catchup_to_date(date=nil)
    date = date.nil? ? Date.today : date
    sql = "select ticker_id, symbol, max(date) as max from daily_closes " +
          "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
    self.connection.select_rows(sql)
  end

end

