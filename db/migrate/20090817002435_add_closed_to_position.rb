class AddClosedToPosition < ActiveRecord::Migration
  def self.up
    add_column :positions, :roi, :float
    add_column :positions, :closed, :boolean
  end

  def self.down
    remove_column :positions, :roi
    remove_column :positions, :closed
  end
end
