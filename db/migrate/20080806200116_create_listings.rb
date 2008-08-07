require 'populate_db'

class CreateListings < ActiveRecord::Migration

  def self.up
    add_listings(Exchange, Ticker, Listing)
  end

  def self.down
    Listing.delete_all
    Ticker.delete_all
    Exchange.delete_all
  end
end
