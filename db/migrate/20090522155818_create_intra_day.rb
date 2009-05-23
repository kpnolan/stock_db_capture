class CreateIntraDay < ActiveRecord::Migration
  def self.up
    DailyBar.connection.execute("create table intra_day_bars like daily_bars")
    rename_column :intra_day_bars, :date, :start_time
    change_column :intra_day_bars, :start_time, :datetime
    add_column :intra_day_bars, :interval, :integer
    add_column :intra_day_bars, :delta, :float
    remove_column :intra_day_bars, :r
  end

  def self.down
    DailyBar.connection.execute("drop table intra_day_bars")
  end
end
