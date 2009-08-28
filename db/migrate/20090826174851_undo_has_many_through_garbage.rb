class UndoHasManyThroughGarbage < ActiveRecord::Migration
  def self.up
    drop_table :backtest_entries
    drop_table :backtest_exits
  end

  def self.down
  end
end
