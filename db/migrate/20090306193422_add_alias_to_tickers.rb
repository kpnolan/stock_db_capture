class AddAliasToTickers < ActiveRecord::Migration
  def self.up
    add_column :tickers, :alias, :string
    add_index :tickers, :alias
  end

  def self.down
    remove_column :tickers, :alias
  end
end
