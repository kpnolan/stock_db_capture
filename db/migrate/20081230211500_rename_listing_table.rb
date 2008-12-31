class RenameListingTable < ActiveRecord::Migration
  def self.up
    rename_table :listings, :current_listings
  end

  def self.down
    rename_table :current_listings, :listings
  end
end
