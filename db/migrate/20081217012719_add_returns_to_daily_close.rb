class AddReturnsToDailyClose < ActiveRecord::Migration
  def self.up
    add_column :daily_closes, :return, :float
    add_column :daily_closes, :log_return, :float
    add_column :daily_closes, :alr, :float
  end

  def self.down
    remove_column :daily_closes, :alr
    remove_column :daily_closes, :log_return
    remove_column :daily_closes, :return
  end
end
