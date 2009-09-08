class CreateTriggerStragegyScans < ActiveRecord::Migration
  def self.up
    create_table(:trigger_strategies_scans, :id => false) do |t|
      t.integer :scan_id
      t.integer :trigger_strategy_id
    end
    drop_table :entry_strategies_scans;
  end

  def self.down
    drop_table :trigger_strategies_scans;
  end
end
