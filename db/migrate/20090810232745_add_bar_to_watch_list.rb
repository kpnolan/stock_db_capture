class AddBarToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :open, :float
    add_column :watch_list, :high, :float
    add_column :watch_list, :low, :float
    add_column :watch_list, :close, :float
    add_column :watch_list, :volume, :integer
    rename_column :watch_list, :curr_price, :price
    remove_column :watch_list, :predicted_ival
  end

  def self.down
    remove_column :watch_list, :volume
    remove_column :watch_list, :close
    remove_column :watch_list, :low
    remove_column :watch_list, :high
    remove_column :watch_list, :open
    rename_column :watch_list, :price, :curr_price
    add_column :watch_list, :predicted_ival, :float
  end
end
