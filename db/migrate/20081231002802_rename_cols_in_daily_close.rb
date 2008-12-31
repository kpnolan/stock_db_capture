class RenameColsInDailyClose < ActiveRecord::Migration
  def self.up
    rename_column :daily_closes, :return, :r
    rename_column :daily_closes, :log_return, :logr
  end

  def self.down
    rename_column :daily_closes, :r, :return
    rename_column :daily_closes, :logr, :log_return
  end
end
