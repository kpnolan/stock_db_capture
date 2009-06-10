class RenameRetyCount < ActiveRecord::Migration
  def self.up
    rename_column :tickers, :rety_count, :retry_count
  end

  def self.down
    rename_column :tickers, :retry_count, :rety_count
  end
end
