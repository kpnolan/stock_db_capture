class AddColumns1ToWatchList < ActiveRecord::Migration
  def self.up
    add_column :watch_list, :current_rsi, :float
    add_column :watch_list, :current_rvi, :float
    add_column :watch_list, :current_macd, :float
    add_column :watch_list, :target_rsi, :float
    add_column :watch_list, :target_rvi, :float
    add_column :watch_list, :target_macd, :float
    add_column :watch_list, :open_crossed_at, :datetime
    add_column :watch_list, :closed_crossed_at, :datetime
    add_column :watch_list, :min_delta, :float
    add_column :watch_list, :nearest_indicator, :string

    remove_column :watch_list, :predicted_price
    remove_column :watch_list, :predicted_sd
    remove_column :watch_list, :snapshots_above
    remove_column :watch_list, :snapshots_below
    remove_column :watch_list, :curr_ival
    remove_column :watch_list, :target_ival
    remove_column :watch_list, :crossed_at
  end

  def self.down
    remove_column :watch_lists, :current_macd
    remove_column :watch_lists, :current_rvi
    remove_column :watch_lists, :current_rsi
    remove_column :watch_lists, :target_macd
    remove_column :watch_lists, :target_rvi
    remove_column :watch_lists, :target_rsi
    remove_column :watch_list, :open_crossed_at
    remove_column :watch_list, :closed_crossed_at
    remove_column :watch_list, :min_delta
    remove_column :watch_list, :nearest_indicator

    add_column :watch_list, :predicted_price, :float
    add_column :watch_list, :predicted_sd, :float
    add_column :watch_list, :snapshots_above, :integer
    add_column :watch_list, :snapshots_below, :integer
    add_column :watch_list, :current_ival, :float
    add_column :watch_list, :target_ival, :float
    add_column :watch_list, :crossed_at, :datetime
  end
end
