class AddAvgVolumeToAggregate < ActiveRecord::Migration
  def self.up
    remove_column :aggregates, :avg_volume
  end

  def self.down
    add_column :aggregates, :avg_volume
  end
end
