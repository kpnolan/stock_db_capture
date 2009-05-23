class CreateDailyBars < ActiveRecord::Migration
  def self.up
    DailyClose.connection.execute("create table daily_bars like daily_closes")
    remove_column :daily_bars, :adj_close
    remove_column :daily_bars, :week
    remove_column :daily_bars, :month
    remove_column :daily_bars, :alr
  end

  def self.down
    DailyClose.connection.execute("drop table daily_bars")
  end
end
