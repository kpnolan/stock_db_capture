class AddLowToIntraDayBar < ActiveRecord::Migration
  def self.up
    add_column :intra_day_bars, :low, :float
  end

  def self.down
    remove_column :intra_day_bars, :low
  end
end
