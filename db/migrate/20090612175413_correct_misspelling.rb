class CorrectMisspelling < ActiveRecord::Migration
  def self.up
    rename_column :intra_day_bars, :accum_valume, :accum_volume
    rename_column :intra_day_archives, :accum_valume, :accum_volume
    rename_column :intra_day_bars, :interval, :period
    rename_column :intra_day_archives, :interval, :period
  end

  def self.down
    rename_column :intra_day_bars, :accum_volume, :accum_valume
    rename_column :intra_day_archives, :accum_volume, :accum_valume
    rename_column :intra_day_bars, :period, :interval
    rename_column :intra_day_archives, :period, :interval
  end
end
