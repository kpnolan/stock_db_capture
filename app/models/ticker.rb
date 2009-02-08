# == Schema Information
# Schema version: 20090207205520
#
# Table name: tickers
#
#  id          :integer(4)      not null, primary key
#  symbol      :string(8)
#  exchange_id :string(255)
#  active      :boolean(1)
#  dormant     :boolean(1)
#

class Ticker < ActiveRecord::Base
  belongs_to :exchange

  has_one  :current_listing
  has_many :real_time_quotes
  has_many :daily_returns
  has_many :daily_closes
  has_many :aggregations

  def listing
    current_listing
  end

  def self.listing_name(symbol)
    (ticker = find_by_symbol(symbol.to_s.upcase)) && ticker.current_listing.name
  end

  def self.symbols
    self.connection.select_values('SELECT symbol FROM tickers ORDER BY symbol')
  end

  def self.active_symbols
    self.connection.select_values('SELECT symbol FROM tickers WHERE active = 1 ORDER BY symbol')
  end

  def self.ids
    self.connection.select_values('SELECT symbol FROM tickers order by id').collect!(&:to_i)
  end

  def self.id_groups(count)
    ids = Ticker.connection.select_values('select id from tickers order by id').collect!(&:to_i)
    ids.in_groups_of(ids.length/count)
  end

  def self.lname(symbol)
    t = find_by_symbol(symbol.to_s.upcase)
    t.current_listing.name.split(' ').collect(&:capitalize).join(' ') if t && t.current_listing
  end
end
