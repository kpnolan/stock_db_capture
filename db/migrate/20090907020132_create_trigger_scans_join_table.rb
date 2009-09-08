class CreateTriggerScansJoinTable < ActiveRecord::Migration
  def self.up
    create_table(:scans_trigger_strategies, :id => false) do |t|
      t.integer :scan_id
      t.integer :trigger_strategy_id
    end
    drop_table :trigger_strategies_scans;
  end

  def self.down
    drop_table :scans_trigger_strategies;
  end
end
