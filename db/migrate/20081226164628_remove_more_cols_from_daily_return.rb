class RemoveMoreColsFromDailyReturn < ActiveRecord::Migration
  def self.up
#    remove_column :daily_returns, :avg_volumn
#    remove_column :daily_returns, :open
    remove_column :daily_returns, :previous_close
    remove_column :daily_returns, :created_at
  end

  def self.down
    add_column :daily_returns, :created_at, :datetime
    add_column :daily_returns, :prev_close, :float
    add_column :daily_returns, :open, :float
    add_column :daily_returns, :avg_volumn, :int
  end
end
