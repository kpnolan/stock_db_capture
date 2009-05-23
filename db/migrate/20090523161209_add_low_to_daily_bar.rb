class AddLowToDailyBar < ActiveRecord::Migration
  def self.up
    add_column :daily_bars, :low, :float
  end

  def self.down
    remove_column :daily_bars, :low
  end
end
