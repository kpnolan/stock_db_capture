class RenameInterval < ActiveRecord::Migration
  def self.up
    rename_column :intra_day_bars, :interval, :period
  end

  def self.down
    rename_column :intra_day_bars, :period, :interval
  end
end
