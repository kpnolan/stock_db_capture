class RenameMacdInWatchList < ActiveRecord::Migration
  def self.up
    rename_column :watch_list, :current_macd, :current_macdfix
    rename_column :watch_list, :target_macd, :target_macdfix
  end

  def self.down
    rename_column :watch_list, :current_macdfix, :current_macd
    rename_column :watch_list, :target_macdfix, :target_macd
  end
end
