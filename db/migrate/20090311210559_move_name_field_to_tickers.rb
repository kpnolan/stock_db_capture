class MoveNameFieldToTickers < ActiveRecord::Migration
  def self.up
    remove_column :current_listings, :name
    add_column :tickers, :name, :string
    remove_column :tickers, :alias
  end

  def self.down
    add_column :current_listings, :name, :string
    remove_column :tickers, :name
    add_column :tickers, :alias
  end
end
