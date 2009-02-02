class AddSampleCountToAggregate < ActiveRecord::Migration
  def self.up
    add_column :aggregates, :sample_count, :integer
  end

  def self.down
    remove_column :aggregates, :sample_count
  end
end
