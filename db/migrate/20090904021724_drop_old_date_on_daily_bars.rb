class DropOldDateOnDailyBars < ActiveRecord::Migration
  def self.up
    remove_index    :daily_bars, :name => :index_daily_bars_on_ticker_id_and_date
    remove_column   :daily_bars, :old_date
    add_index       :daily_bars, [:ticker_id, :bartime], :unique => true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
