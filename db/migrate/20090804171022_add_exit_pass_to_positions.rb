class AddExitPassToPositions < ActiveRecord::Migration
  def self.up
    remove_column :positions, :exit_pass
  end

  def self.down
    add_column :positions, :exit_pass, :integer
  end
end
