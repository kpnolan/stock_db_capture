class CreateEntryStragiesScans < ActiveRecord::Migration
  def self.up
    create_table(:entry_strategies_scans, :id => false) do |t|
      t.integer :scan_id
      t.integer :entry_strategy_id
    end
  end

  def self.down
    drop_table :entry_strategies_scans;
  end
end
