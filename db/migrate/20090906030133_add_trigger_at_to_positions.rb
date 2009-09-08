class AddTriggerAtToPositions < ActiveRecord::Migration
  def self.up
    add_column :positions, :triggered_at, :datetime
  end

  def self.down
    remove_column :positions, :triggered_at
  end
end
