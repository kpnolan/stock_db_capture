class AddIndexToDailyBars < ActiveRecord::Migration
  def self.up
    add_index :daily_bars, [:ticker_id, :date]
  end

  def self.down
    remove_index :daily_bars, [:ticker_id, :date]
  end
end
