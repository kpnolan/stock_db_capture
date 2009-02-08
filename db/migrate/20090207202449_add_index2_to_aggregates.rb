class AddIndex2ToAggregates < ActiveRecord::Migration
  def self.up
    add_index :aggregates, [:ticker_id, :date]
  end

  def self.down
    remove_index :aggregates, :column => [:ticker_id, :date]
  end
end
