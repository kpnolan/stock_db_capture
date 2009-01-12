class AddColumnsToAggregate < ActiveRecord::Migration
  def self.up
    add_column :aggregates, :r, :float
    add_column :aggregates, :logr, :float
  end

  def self.down
    remove_column :aggregates, :logr
    remove_column :aggregates, :r
  end
end
