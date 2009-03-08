class ChangeTickerIndexToUnique < ActiveRecord::Migration
  def self.up
    remove_index :tickers, :symbol
    add_index :tickers, :symbol, :unique => true
  end

  def self.down
  end
end
