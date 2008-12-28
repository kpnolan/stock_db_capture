class RenameTable < ActiveRecord::Migration
  def self.up
    rename_table :daily_returns, :live_quotes
  end

  def self.down
    rename table :live_quotes, :daily_returns
  end
end
