class AddIndexToLiveQuotes < ActiveRecord::Migration
  def self.up
    add_index :live_quotes, [ :ticker_id, :last_trade_time ], :unique => true
  end

  def self.down
    remove_index :live_quotes
  end
end
