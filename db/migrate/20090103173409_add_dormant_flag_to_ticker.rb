class AddDormantFlagToTicker < ActiveRecord::Migration
  def self.up
    add_column :tickers, :dormant, :boolean, :default => false
  end

  def self.down
    remove_column :tickers, :dormant
  end
end
