class Ticker < ActiveRecord::Base
  belongs_to :exchange

  has_many :listings
  has_many :real_time_quotes
  has_many :daily_returns
  has_many :daily_closes
  has_many :aggregations

  def self.symbols
    self.connection.select_values('SELECT symbol FROM tickers')
  end
end
