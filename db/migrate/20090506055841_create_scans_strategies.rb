class CreateScansStrategies < ActiveRecord::Migration
  def self.up
    create_table(:scans_strategies, :id => false) do |t|
      t.integer :scan_id
      t.integer :strategy_id

      t.timestamps
    end
  end

  def self.down
    drop_table :scans_strategies
  end
end
