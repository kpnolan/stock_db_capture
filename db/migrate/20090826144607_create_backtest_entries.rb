class CreateBacktestEntries < ActiveRecord::Migration
  def self.up
    create_table :backtest_entries do |t|
      t.integer :entry_strategy_id
      t.integer :position_id, :references => nil
      t.integer :scan_id
    end
  end

  def self.down
    drop_table :backtest_entries
  end
end
