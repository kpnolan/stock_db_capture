class AddActiveToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :active, :boolean
  end

  def self.down
    remove_column :tickers, :active
  end
end
