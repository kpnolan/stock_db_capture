class AddDelistedToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :delisted, :boolean, :default => 0
  end

  def self.down
    remove_column :tickers, :delisted
  end
end
