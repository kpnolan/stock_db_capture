class AddLockedFlagToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :locked, :boolean
  end

  def self.down
    remove_column :tickers, :locked
  end
end
