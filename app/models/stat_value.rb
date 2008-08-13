class StatValue < ActiveRecord::Base

  belongs_to :ticker

  def self.create_row(attr, ticker, start_date, end_date, attr_hash)
    attr_hash.merge!(:ticker_id => ticker.id,
                     :historical_attribute_id => HistoricalAttribute.find_by_name(attr),
                     :start_date => start_date,
                     :end_date => end_date)
    create(attr_hash)
  end
end
