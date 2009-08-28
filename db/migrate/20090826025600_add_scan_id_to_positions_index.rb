class AddScanIdToPositionsIndex < ActiveRecord::Migration
  def self.up
    remove_column :positions, :entry_trigger
    remove_column :positions, :strategy_id
    add_column :positions, :entry_strategy_id, :integer
    add_column :positions, :exit_strategy_id, :integer
    add_index :positions, [:ticker_id, :scan_id, :entry_strategy_id, :exit_strategy_id, :entry_date], :unique => true, :name => :unique_param_ids
  end

  def self.down
    remove_index :positions, :name => :unique_param_ids
    remove_column :positions, :entry_strategy_id
    remove_column :positions, :exit_strategy_id
    add_column :entry_trigger, :float
    add_column :positions, :strategy_id, :integer
  end
end
