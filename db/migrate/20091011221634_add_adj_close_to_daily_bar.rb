class AddAdjCloseToDailyBar < ActiveRecord::Migration
  def self.up
    remove_column :daily_bars, :interpolated
    add_column :daily_bars, :adj_close, :float
  end

  def self.down
    remove_column :daily_bars, :adj_close
    add_column :daily_bars, :interplated, :boolean
  end
end
