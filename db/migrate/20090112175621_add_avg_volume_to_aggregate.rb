class AddAvgVolumeToAggregate < ActiveRecord::Migration
  def self.up
    add_column :aggregates, :avg_volume, :integer
  end

  def self.down
    remove_column :aggregates, :avg_volume
  end
end
