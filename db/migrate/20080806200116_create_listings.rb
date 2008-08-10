require 'populate_db'

class CreateListings < ActiveRecord::Migration

  def self.up
    create_table :listings do |t|
      TradingDBLoader.create_table_from_fields(t, :listings, 'x')
    end
  end

  def self.down
    drop_table :listings
  end
end
