class AddStaleDateToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :stale_date, :date
  end

  def self.down
    remove_column :watch_list, :stale_date
  end
end
