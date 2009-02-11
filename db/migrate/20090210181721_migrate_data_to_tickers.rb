class MigrateDataToTickers < ActiveRecord::Migration
  def self.up
   rows = Ticker.connection.select_rows("select ticker_id, max(last_trade_time) from live_quotes group by ticker_id order by ticker_id")
    for row in rows
      ticker_id, last_trade_time = row
      t = Ticker.find ticker_id
      t.update_attribute(:last_trade_time, last_trade_time)
    end
  end

  def self.down
  end
end
