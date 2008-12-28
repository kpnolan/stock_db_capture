class RemoveFieldFromDailyReturn < ActiveRecord::Migration
  def self.up
    remove_column :daily_returns, :bid
    remove_column :daily_returns, :ask
    remove_column :daily_returns, :tickertrend
    remove_column :daily_returns, :last_trade_date
    remove_column :daily_returns, :day_low
    remove_column :daily_returns, :day_range_high
    remove_column :daily_returns, :day_range_low
    remove_column :daily_returns, :day_high
    remove_column :daily_returns, :open
    remove_column :daily_returns, :previous_close
    remove_column :daily_returns, :avg_volumn
    remove_column :daily_returns, :updated_at
    remove_column :daily_returns, :created_at
  end

  def self.down
    add_column :daily_returns, :updated_at, :float
    add_column :daily_returns, :day_high, :float
    add_column :daily_returns, :day_low, :float
    add_column :daily_returns, :last_trade_date, :date
    add_column :daily_returns, :tickertrend, :string
    add_column :daily_returns, :ask, :float
    add_column :daily_returns, :bid, :fload
    add_column :daily_returns, :day_range_high, :float
    add_column :daily_returns, :day_range_low, :float
  end
end
