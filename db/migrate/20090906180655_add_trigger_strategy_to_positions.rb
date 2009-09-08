class AddTriggerStrategyToPositions < ActiveRecord::Migration
  def self.up
    add_column :positions, :trigger_strategy_id, :integer
  end

  def self.down
    remove_column :positions, :trigger_strategy_id
  end
end
