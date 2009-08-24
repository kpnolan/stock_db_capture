class ReogColumnsWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :opened_on, :date
    remove_column :watch_list, :stale_date
  end

  def self.down
    remove_column :watch_list, :opened_on
    add_column :watch_list, :opened_on, :date
  end
end
