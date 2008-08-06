require 'populate_db'

class PopulateTickerTable < ActiveRecord::Migration
  def self.up
    add_tickers(Exchange, Ticker)
  end

  def self.down
    Exchange.delete_all
    Ticker.delete_all
  end
end
