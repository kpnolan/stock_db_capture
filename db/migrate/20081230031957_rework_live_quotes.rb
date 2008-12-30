class ReworkLiveQuotes < ActiveRecord::Migration
  def self.up
    rename_column :live_quotes, :change_percent, :r
    add_column :live_quotes, :logr, :float
  end

  def self.down
    rename_column :live_quotes, :r, :change_percent
    remove_column :live_quotes, :logr
  end
end
