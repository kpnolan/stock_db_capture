class AddAdjCloseToYahooBar < ActiveRecord::Migration
  def self.up
    add_column :yahoo_bars, :adj_close, :float
  end

  def self.down
    remove_column :yahoo_bars, :adj_close
  end
end
