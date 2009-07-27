class AddNumSamplesToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :num_samples, :integer
  end

  def self.down
    remove_column :watch_list, :num_samples
  end
end
