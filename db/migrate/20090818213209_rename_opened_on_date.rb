class RenameOpenedOnDate < ActiveRecord::Migration
  def self.up
    rename_column :watch_list, :entered_on, :listed_on
  end

  def self.down
    rename_column :watch_list, :listed_on, :entered_on
  end
end
