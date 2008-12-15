class CreateRealTimeQuotes < ActiveRecord::Migration
  def self.up
    create_table :real_time_quotes, :force => true do |t|
      t.float :last_trade
      t.float :ask
      t.float :bid
      t.datetime :last_trade_time
      t.float :change
      t.float :change_points
      t.integer :ticker_id
      t.datetime :created_at
      t.datetime :updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :real_time_quotes
  end
end
