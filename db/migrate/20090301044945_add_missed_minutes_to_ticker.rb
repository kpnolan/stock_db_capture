class AddMissedMinutesToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :missed_minutes, :integer, :default => 0
  end

  def self.down
    remove_column :tickers, :missed_minutes
  end
end
