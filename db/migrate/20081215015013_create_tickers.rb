class CreateTickers < ActiveRecord::Migration
  def self.up
    create_table :tickers, :force => true do |t|
      t.string :symbol
      t.integer :exchange_id
      t.timestamps
    end
  end

  def self.down
    drop_table :tickers
  end
end
