require 'populate_db'

class CreateTickers < ActiveRecord::Migration
  def self.up
     create_table :tickers do |t|
       t.string :symbol, :limit => 8
       t.string :exchange_id
     end
    add_index :tickers, :symbol, :uniq => true
  end

  def self.down
    drop_table :tickers
  end
end
