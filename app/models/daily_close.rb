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

  ATTRS = [ :close, :open, :high, :low, :adj_close, :volume, :date ]

  def self.get_vectors(ticker, attrs=ATTRS, bdate=nil, edate=nil)
    case
      when ticker.class == Fixnum : ticker_id = ticker
      when ticker.class == Symbol : ticker_id = Ticker.find_by_symbol(ticker.to_s.upcase).id
      when ticker.class == String : ticker_id = Ticker.find_by_symbol(ticker.upcase).id
    else
      raise ArgumentError, 'ticker should be Fixnum or String'
    end
    dc = DailyClose.find(:all, :conditions => form_conditions(ticker_id, bdate, edate), :order => 'date')
    result = { }
    attrs.each { |attr| result[attr.to_sym] = dc.collect(&attr) }

    return result
  end

  def self.form_conditions(id, bdate, edate)
    case
      when bdate && edate   : [ 'ticker_id = ? AND date >= ? AND date <= ?', id, bdate.to_date, edate.to_date ]
      when bdate            : [ 'ticker_id = ? AND date >= ? ', id, bdate.to_date ]
      when edate            : [ 'ticker_id = ? AND date <= ?' , id, edate.to_date ]
      else                    [ 'ticker_id = ?', id ]
    end
  end
end

