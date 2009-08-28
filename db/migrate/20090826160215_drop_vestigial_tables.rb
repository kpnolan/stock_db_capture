class DropVestigialTables < ActiveRecord::Migration
  def self.up
    drop_table :scans_strategies
    drop_table :slopes
    drop_table :cstats
    drop_table :bar_lookup
  end

  def self.down
  end
end
