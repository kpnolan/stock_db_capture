class CreateDailyReturns < ActiveRecord::Migration
  def self.up
    create_table :daily_returns, :force => true do |t|
      t.integer :volume
      t.float :ask
      t.float :bid
      t.float :day_range_low
      t.float :day_range_high
      t.float :change_percent
      t.date :last_trade_date
      t.string :tickertrend
      t.float :change_points
      t.float :open
      t.float :previous_close
      t.float :last_trade
      t.integer :avg_volumn
      t.float :day_low
      t.datetime :last_trade_time
      t.float :day_high
      t.integer :ticker_id
      t.datetime :created_at
      t.datetime :updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_returns
  end
end
