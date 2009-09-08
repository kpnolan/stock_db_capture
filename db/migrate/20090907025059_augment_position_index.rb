class AugmentPositionIndex < ActiveRecord::Migration
  def self.up
    add_index :positions, [:ticker_id, :scan_id, :trigger_strategy_id, :entry_strategy_id, :exit_strategy_id, :triggered_at], :unique => true, :name => :unique_param_ids
  end

  def self.down
    remove_index :positions, :name => :unique_param_ids
  end
end
