class AddTriggersToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :entry_trigger, :float
    add_column :positions, :exit_trigger, :float
    remove_column :positions, :week
  end

  def self.down
    remove_column :positions, :exit_trigger
    remove_column :positions, :entry_trigger
    add_column :positions, :week, :integer
  end
end
