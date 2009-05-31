class AddAccumVolumeToIntraDayBar < ActiveRecord::Migration
  def self.up
    add_column :intra_day_bars, :accum_volume, :float
  end

  def self.down
    remove_column :intra_day_bars, :accum_volume
  end
end
