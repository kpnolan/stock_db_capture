class AddIndexToAggregate < ActiveRecord::Migration
  def self.up
    add_index(:aggregates, [:ticker_id, :start, :period])
  end

  def self.down
    remove_index(:aggregates)
  end
end
