class AddLastTradeToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :last_trade_time, :datetime
    remove_index :live_quotes, :column => [:ticker_id, :last_trade_time]
    remove_index :live_quotes, :column => [:ticker_id, :date]
    remove_column :live_quotes, :r
    remove_column :live_quotes, :logr
    remove_column :live_quotes, :date
    add_index :tickers, [:id, :last_trade_time]
  end

  def self.down
    remove_column :tickers, :last_trade_time
    add_column :live_quotes, :r, :float
    add_column :live_quotes, :logr, :float
    add_column :live_quotes, :date, :float
    remove_index :tickers, :column => [ :id, :last_trade_time ]
    add_index :live_quotes,  [:ticker_id, :last_trade_time]
    add_index :live_quotes,  [:ticker_id, :date]
  end
end
