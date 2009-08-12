class AddEntryDateToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :entered_on, :date
    add_column :watch_list, :closed_on, :date
  end

  def self.down
    remove_column :watch_list, :entered_on
    remove_column :watch_list, :closed_on
  end
end
