class RemoveVestigialColumnsFromAggregate < ActiveRecord::Migration
  def self.up
    remove_columns :aggregates, :period, :sample_count
    remove_index :aggregates, [:ticker_id, :start, :period ]
  end

  def self.down
    add_column :aggregates, :period, :integer
    add_column :aggregates, :sample_count, :integer
    add_index :aggregates, [:ticker_id, :start ]
  end
end
