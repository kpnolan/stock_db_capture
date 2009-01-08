# == Schema Information
# Schema version: 20081230211500
#
# Table name: daily_closes
#
#  id         :integer(4)      not null, primary key
#  ticker_id  :integer(4)      not null
#  date       :date
#  open       :float
#  close      :float
#  high       :float
#  low        :float
#  adj_close  :float
#  volume     :integer(4)
#  week       :integer(4)
#  month      :integer(4)
#  return     :float
#  log_return :float
#  alr        :float
#

class DailyClose < ActiveRecord::Base
  belongs_to :ticker

  extend TableExtract
  extend Plot

  def symbol=(value) ;  end
  def last_trade_date=(value) ;  end
  def self.order ; 'date, id'; end
  def self.time_col ; :date ;  end
  def self.time_convert ; :to_date ;  end
  def self.time_class ; Date ;  end
  def self.time_res; 1; end

  def self.catchup_to_date(date=nil)
    date = date.nil? ? Date.today : date
    sql = "select ticker_id, symbol, max(date) as max from daily_closes " +
          "left join tickers on tickers.id = ticker_id group by ticker_id having max != #{date.to_s(:db)}";
    self.connection.select_rows(sql)
  end
end

