# == Schema Information
# Schema version: 20081227180640
#
# Table name: tickers
#
#  id          :integer(4)      not null, primary key
#  symbol      :string(8)
#  exchange_id :string(255)
#  active      :boolean(1)
#

class Ticker < ActiveRecord::Base
  belongs_to :exchange

  has_one :listing
  has_many :real_time_quotes
  has_many :daily_returns
  has_many :daily_closes
  has_many :aggregations

  def self.symbols
    self.connection.select_values('SELECT symbol FROM tickers ORDER BY symbol WHERE active = 1')
  end

  def self.ids
    self.connection.select_values('SELECT symbol FROM tickers order by id').collect!(&:to_i)
  end

  def self.id_groups(count)
    ids = Ticker.connection.select_values('select id from tickers order by id').collect!(&:to_i)
    ids.in_groups_of(ids.length/count)
  end
end
