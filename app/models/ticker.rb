# == Schema Information
# Schema version: 20080813192644
#
# Table name: tickers
#
#  id          :integer(4)      not null, primary key
#  symbol      :string(8)
#  exchange_id :string(255)
#

class Ticker < ActiveRecord::Base
  belongs_to :exchange

  has_one :listing
  has_many :real_time_quotes
  has_many :daily_returns
  has_many :daily_closes
  has_many :aggregations

  def self.symbols
    self.connection.select_values('SELECT symbol FROM tickers')
  end
end
