class AddUniqueKeyToAggregates < ActiveRecord::Migration
  def self.up
    add_index(:aggregates, [:ticker_id, :start, :period], :unique => true)
  end

  def self.down
    remove_index(:aggregates)
  end
end
