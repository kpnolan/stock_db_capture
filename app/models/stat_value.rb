class StatValue < ActiveRecord::Base

  belongs_to :ticker_id

  def self.create_row(attr, ticker_name, start_date, end_date, attr_hash)
    ha = HistoricalAttribute.find_by_name(attr)
    ticker = Ticker.find_by_symbol(ticker_name)
    ar = create(attr_hash.merge(:ticker_id => ticker.id,
                           :historical_attribute_id => ha.id,
                           :start_date => start_date,
                           :end_date => end_date))
    debugger
  end
end
