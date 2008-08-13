require 'populate_db'

class CreateListingCategories < ActiveRecord::Migration
  def self.up
    create_table :listing_categories do |t|
      t.string :name
    end
    begin
      TradingDBLoader.load_listing_categories()
    rescue
      drop_table :listing_categories
      raise
    end
  end

  def self.down
    drop_table :listing_categories
  end
end
