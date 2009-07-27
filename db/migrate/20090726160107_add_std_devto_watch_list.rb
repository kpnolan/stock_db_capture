class AddStdDevtoWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :predicted_sd, :float
  end

  def self.down
    remove_column :watch_list, :predicted_sd, :float
  end
end
