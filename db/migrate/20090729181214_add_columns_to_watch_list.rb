class AddColumnsToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :snapshots_above, :integer, :default => 0, :null => false
    add_column :watch_list, :snapshots_below, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :watch_list, :snapshots_below
    remove_column :watch_list, :snapshots_above
  end
end
