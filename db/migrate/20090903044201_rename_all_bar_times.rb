class RenameAllBarTimes < ActiveRecord::Migration
  def self.up
    rename_column :snapshots, :snaptime, :bartime
    rename_column :intra_day_bars, :start_time, :bartime
    rename_column :daily_bars, :date, :bartime
  end

  def self.down
    rename_column :snapshots, :bartime, :snaptime
    rename_column :intra_day_bars, :bartime, :start_time
    rename_column :daily_bars, :bartime, :date
  end
end
