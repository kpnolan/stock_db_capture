class CreateBacktestExits < ActiveRecord::Migration
  def self.up
    create_table :backtest_exits do |t|
      t.integer :exit_strategy_id
      t.integer :position_id, :references => nil
      t.integer :scan_id
    end
  end

  def self.down
    drop_table :backtest_exits
  end
end
