class RenameOpenToOpening < ActiveRecord::Migration
  def self.up
    rename_column :daily_bars, :open, :opening
    rename_column :intra_day_bars, :open, :opening
    rename_column :snapshots, :open, :opening
    rename_column :watch_list, :open, :opening
  end

  def self.down
    rename_column :daily_bars, :opening, :open
    rename_column :intra_day_bars, :opening, :open
    rename_column :snapshot, :opening, :open
    rename_column :watch_list, :opening, :open
  end
end
