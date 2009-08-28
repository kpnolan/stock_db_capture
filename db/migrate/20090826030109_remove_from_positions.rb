class RemoveFromPositions < ActiveRecord::Migration
  def self.up
    remove_column :positions, :exit_trigger
  end

  def self.down
    add_column :positions, :exit_trigger, :float
  end
end
