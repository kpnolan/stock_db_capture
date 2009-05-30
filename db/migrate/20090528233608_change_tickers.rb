class ChangeTickers < ActiveRecord::Migration
  def self.up
    add_column    :tickers, :etf, :boolean
    add_column    :tickers, :sector_id, :integer
    add_column    :tickers, :industry_id, :integer
    rename_column :tickers, :missed_minutes, :rety_count
    remove_column :tickers, :dormant
    remove_column :tickers, :validated
    remove_column :tickers, :last_trade_time
  end

  def self.down
    remove_column :tickers, :etf
    remove_column :tickers, :sector_id
    remove_column :tickers, :industry_id
    rename_column :tickers, :rety_count, :missed_minutes
    remove_column :tickers, :dormant, :boolean
    remove_column :tickers, :validated, :boolean
    remove_column :tickers, :last_trade_time, :boolean
  end
end
