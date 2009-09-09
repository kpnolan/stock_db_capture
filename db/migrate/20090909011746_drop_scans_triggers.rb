class DropScansTriggers < ActiveRecord::Migration
  def self.up
    drop_table :scans_trigger_strategies
  end

  def self.down
    create_table(:scans_trigger_strategies, :id => false) do |t|
      t.integer :scan_id
      t.integer :trigger_strategy_id
    end
  end
end
